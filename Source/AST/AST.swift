////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

// Inspired by: https://github.com/chriseidhof/commonmark-swift

import UIKit
import Foundation
import libcmark

// MARK: - DEFINITIONS

protocol Renderable {
    func render(with style: DownStyle) -> NSMutableAttributedString?
}

enum ListType : CustomStringConvertible {
    case ordered(start: Int)
    case unordered
    
    init?(node: Node) {
        guard node.type == CMARK_NODE_LIST else { return nil }
        switch node.listType {
        case CMARK_ORDERED_LIST:    self = .ordered(start: node.listStart)
        default:                    self = .unordered
        }
    }
    
    /// Returns the prefix for the this lists item at the given index.
    func prefix(itemIndex: Int) -> String {
        // the tabs are used to align the list item content
        switch self {
        case .ordered(let start):   return "\(start + itemIndex)."
        case .unordered:            return "•"
        }
    }
    
    /// Returns the markdown identifier associated with the list type.
    var markdownID: Markdown {
        switch self {
        case .ordered(start: _):    return .oList
        case .unordered:            return .uList
        }
    }
    
    var description: String {
        switch self {
        case .ordered(let start):   return "Ordered: Start: \(start)"
        case .unordered:            return "Unordered"
        }
    }
}

enum Block {
    case document(children: [Block])
    case blockQuote(items: [Block])
    case list(items: [Block], type: ListType)
    case listItem(children: [Block], prefix: String)
    case codeBlock(text: String)
    case htmlBlock(text: String)
    case customBlock(literal: String)
    case paragraph(children: [Inline])
    case heading(children: [Inline], level: Int)
    case thematicBreak
}

enum Inline {
    case text(text: String)
    case softBreak
    case lineBreak
    case code(text: String)
    case html(text: String)
    case custom(literal: String)
    case emphasis(children: [Inline])
    case strong(children: [Inline])
    case link(children: [Inline], title: String?, url: String?)
    case image(children: [Inline], title: String?, url: String?)
}

// MARK: - INITIALIZERS

extension Block {
    init(_ node: Node) {
        let inlineChildren = { node.children.map(Inline.init) }
        let blockChildren = { node.children.map(Block.init) }
        
        switch node.type {
        case CMARK_NODE_DOCUMENT:
            self = .document(children: blockChildren())
            
        case CMARK_NODE_BLOCK_QUOTE:
            self = .blockQuote(items: blockChildren())
            
        case CMARK_NODE_LIST:
            let listType = ListType(node: node) ?? .ordered(start: 0)
            
            // we process the lists items here so that we can prepend their prefixes
            var items = [Block]()
            for (idx, item) in node.children.enumerated() {
                items.append(.listItem(children: item.children.map(Block.init), prefix: listType.prefix(itemIndex: idx)))
            }
            
            self = .list(items: items, type: listType)
            
        case CMARK_NODE_ITEM:
            fatalError("Can't create list item here!")
            
        case CMARK_NODE_CODE_BLOCK:
            self = .codeBlock(text: node.literal!)
            
        case CMARK_NODE_HTML_BLOCK:
            self = .htmlBlock(text: node.literal!)
            
        case CMARK_NODE_CUSTOM_BLOCK:
            self = .customBlock(literal: node.literal!)
            
        case CMARK_NODE_PARAGRAPH:
            self = .paragraph(children: inlineChildren())
            
        case CMARK_NODE_HEADING:
            self = .heading(children: inlineChildren(), level: node.headerLevel)
            
        case CMARK_NODE_THEMATIC_BREAK:
            self = .thematicBreak
            
        default:
            fatalError("Unknown node: \(node.typeString)")
        }
    }
    
}

extension Inline {
    init(_ node: Node) {
        let inlineChildren = { node.children.map(Inline.init) }
        
        switch node.type {
        case CMARK_NODE_TEXT:
            self = .text(text: node.literal!)
            
        case CMARK_NODE_SOFTBREAK:
            self = .softBreak
            
        case CMARK_NODE_LINEBREAK:
            self = .lineBreak
            
        case CMARK_NODE_CODE:
            self = .code(text: node.literal!)
            
        case CMARK_NODE_HTML_INLINE:
            self = .html(text: node.literal!)
            
        case CMARK_NODE_CUSTOM_INLINE:
            self = .custom(literal: node.literal!)
            
        case CMARK_NODE_EMPH:
            self = .emphasis(children: inlineChildren())
            
        case CMARK_NODE_STRONG:
            self = .strong(children: inlineChildren())
            
        case CMARK_NODE_LINK:
            self = .link(children: inlineChildren(), title: node.title, url: node.urlString)
            
        case CMARK_NODE_IMAGE:
            self = .image(children: inlineChildren(), title: node.title, url: node.urlString)
            
        default:
            fatalError("Unknown node: \(node.typeString)")
        }
    }
}

// MARK: - RENDER HELPERS

fileprivate extension Sequence where Iterator.Element == Block {
    /// Calls render(with style:) to each element in the sequence and returns
    /// the concatenation of their results.
    func render(with style: DownStyle) -> NSMutableAttributedString {
        return self.map { $0.render(with: style) }.join()
    }
}

fileprivate extension Sequence where Iterator.Element == Inline {
    /// Calls render(with style:) to each element in the sequence and returns
    /// the concatenation of their results.
    func render(with style: DownStyle) -> NSMutableAttributedString {
        return self.map { $0.render(with: style) }.join()
    }
}

// MARK: - RENDERING

extension Block : Renderable {
    /// Renders the tree rooted at the current node with the given style.
    func render(with style: DownStyle) -> NSMutableAttributedString? {
        let attrs = style.attributes(for: self)
        
        switch self {
        case .document(let children):
            return children.render(with: style)
            
        case .blockQuote(let items):
            let content = items.render(with: style)
            content.addAttributes(attrs)
            return content
            
        case .list(let items, let type):
            
            // standard prefix width
            var prefixMarginWidth = style.minListPrefixWidth
            
            // last item will be the largest
            if let lastItem = items.last {
                switch lastItem {
                case .listItem(_, let prefix):
                    prefixMarginWidth = max(prefixMarginWidth, style.widthOfListPrefix(prefix))
                default:
                    break
                }
            }
            
            // position where item text begins
            let rule = prefixMarginWidth + style.listItemPrefixSpacing
            
            // rendering the items
            let content = items.map { (item: Block) -> NSMutableAttributedString? in
                switch item {
                case .listItem(let children, let prefix):
                    // render the content of this item first
                    let content = children.render(with: style)
                    let attrPrefix = NSMutableAttributedString(string: prefix, attributes: style.listPrefixAttributes)
                    let space = NSMutableAttributedString(string: "\t")
                    let result = [attrPrefix, space, content].join()
                    
                    // each item has it's own paragraph style
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.paragraphSpacing = 8
                    
                    // content is left aligned at the rule and wraps to this rule
                    paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: rule, options: [:])]
                    paragraphStyle.headIndent = rule
                    
                    // make the prefixes align right to the prefix margin (we push it as much as it is small than the margin)
                    paragraphStyle.firstLineHeadIndent = prefixMarginWidth - attrPrefix.size().width
                    
                    // we want bullet points to line up with the last digit of a number item, not the dot
                    if prefix == "•" {
                        paragraphStyle.firstLineHeadIndent -= style.widthOfListPrefix(".")
                    }
                    
                    // need to extract existing styles of any nested lists
                    let rangesOfNestedLists = result.ranges(containing: .oList) + result.ranges(containing: .uList)
                    
                    var existingStyles: [(NSParagraphStyle, NSRange)] = []
                    
                    rangesOfNestedLists.forEach {
                        let attributeRanges: [(NSParagraphStyle, NSRange)] = result.attributeRanges(for: .paragraphStyle, in: $0)
                        existingStyles.append(contentsOf: attributeRanges)
                    }
                    
                    // insert markdown id for the list
                    result.add(markdownIdentifier: type.markdownID)
                    
                    // apply the paragraph style for this item
                    result.addAttribute(.paragraphStyle, value: paragraphStyle)
                    
                    // apply the updated paragraph styles for the inner lists
                    for (val, range) in existingStyles {
                        result.addAttribute(.paragraphStyle, value: val.indentedBy(points: rule), range: range)
                    }
                    
                    return result
                    
                default:
                    return nil
                }
            }.join()
            
            return content
            
        case .listItem(_, _):
            return nil
            
        case .codeBlock(let text):
            return NSMutableAttributedString(string: text, attributes: attrs)
            
        case .htmlBlock(let text):
            return NSMutableAttributedString(string: text, attributes: attrs)
            
        case .customBlock(let literal):
            return NSMutableAttributedString(string: literal, attributes: attrs)
            
        case .paragraph(let children):
            let content = children.render(with: style)

            let breakAttributes = style.attributes(for: self)

            content.appendBreak(attributes: breakAttributes)
            return content
            
        case .heading(let children, let level):
            let content = children.render(with: style)
            content.bolden(with: style.headerSize(for: level))
            content.addAttributes(attrs)
            content.appendBreak()
            return content
            
        case .thematicBreak:
            return nil
        }
    }
}

extension Inline : Renderable {
    /// Renders the tree rooted at the current node with the given style.
    func render(with style: DownStyle) -> NSMutableAttributedString? {
        let attrs = style.attributes(for: self)
        
        switch self {
        case .text(let text):
            return NSMutableAttributedString(string: text, attributes: attrs)
            
        case .softBreak:
            return NSMutableAttributedString(string: "\n")
            
        case .lineBreak:
            return NSMutableAttributedString(string: "\n")
            
        case .code(let text):
            return NSMutableAttributedString(string: text, attributes: attrs)
            
        case .html(let text):
            return NSMutableAttributedString(string: text, attributes: attrs)
            
        case .custom(let literal):
            return NSMutableAttributedString(string: literal, attributes: attrs)
            
        case .emphasis(let children):
            let content = children.render(with: style)
            content.italicize()
            content.addAttributes(attrs)
            return content
            
        case .strong(let children):
            let content = children.render(with: style)
            content.bolden()
            content.addAttributes(attrs)
            return content
            
        case .link(let children, title: _, let urlStr):
            let content = children.render(with: style)

            guard style.renderOnlyValidLinks else {
                if let url = urlStr.flatMap(Foundation.URL.init(string:)) {
                    styleLink(content: content, url: url, style: style)
                }

                return content
            }

            if let url = urlStr?.detectedURL, Application.shared.canOpenURL(url) {
                styleLink(content: content, url: url, style: style)
                return content
            } else {
                // the link isn't valid, so we just display the input text
                return NSMutableAttributedString(string: "[\(content.string)](\(urlStr ?? ""))", attributes: style.defaultAttributes)
            }
            
        case .image(let children, title: _, url: _):
            let content = children.render(with: style)
            return content
        }
    }

    private func styleLink(content: NSMutableAttributedString, url: URL, style: DownStyle) {
        // overwrite styling to avoid bold, italic, code links
        content.addAttributes(style.defaultAttributes)
        content.addAttribute(.markdown, value: Markdown.link, range: content.wholeRange)
        content.addAttribute(.link, value: url, range: content.wholeRange)
    }

}

// MARK: - STRING DESCRIPTION

extension Block : CustomStringConvertible {
    /// Describes the tree rooted at this node.
    var description: String {
        return description(indent: 0)
    }
    
    /// Returns the description with the given indentation.
    func description(indent: Int) -> String {
        var str: String
        let describeBlockChildren: (Block) -> String = { $0.description(indent: indent + 1) }
        let describeInlineChildren: (Inline) -> String = { $0.description(indent: indent + 1) }
        
        switch self {
        case .document(let children):
            str = "DOCUMENT ->\n" + children.flatMap(describeBlockChildren)
            
        case .blockQuote(let items):
            str = "BLOCK QUOTE ->\n" + items.flatMap(describeBlockChildren)
            
        case .list(let items, let type):
            
            str = "LIST: \(type) ->\n" + items.flatMap(describeBlockChildren)
            
        case .listItem(let children, let prefix):
            str = "ITEM: Prefix: \(prefix) ->\n" + children.flatMap(describeBlockChildren)
            
        case .codeBlock(let text):
            str = "CODE BLOCK: \(text)\n"
            
        case .htmlBlock(let text):
            str = "HTML BLOCK: \(text)\n"
            
        case .customBlock(let literal):
            str = "CUSTOM BLOCK: \(literal)\n"
            
        case .paragraph(let children):
            str = "PARAGRAPH ->\n" + children.flatMap(describeInlineChildren)
            
        case .heading(let children, let level):
            str = "H\(level) HEADING ->\n" + children.flatMap(describeInlineChildren)
            
        case .thematicBreak:
            str = "THEMATIC BREAK ->\n"
        }
        
        return String(repeating: "\t", count: indent) + str
    }
}

extension Inline : CustomStringConvertible {
    /// Describes the tree rooted at this node.
    var description: String {
        return description(indent: 0)
    }
    
    /// Returns the description with the given indentation.
    func description(indent: Int) -> String {
        var str: String
        let describeChildren: (Inline) -> String = { $0.description(indent: indent + 1) }
        
        switch self {
        case .text(let text):
            str = "TEXT: \(text)\n"
            
        case .softBreak:
            str = "SOFT BREAK\n"
            
        case .lineBreak:
            str = "LINE BREAK\n"
            
        case .code(let text):
            str = "CODE: \(text)\n"
            
        case .html(let text):
            str = "HTML: \(text)\n"
            
        case .custom(let literal):
            str = "CUSTOM INLINE: \(literal)\n"
            
        case .emphasis(let children):
            str = "EMPHASIS ->\n" + children.flatMap(describeChildren)
            
        case .strong(let children):
            str = "STRONG ->\n" + children.flatMap(describeChildren)
            
        case .link(let children, let title, let url):
            str = "LINK: Title: \(title ?? "none"), URL: \(url ?? "none") ->\n" + children.flatMap(describeChildren)
            
        case .image(let children, let title, let url):
            str = "IMAGE: Title: \(title ?? "none"), URL: \(url ?? "none") ->\n" + children.flatMap(describeChildren)
        }
        
        return String(repeating: "\t", count: indent) + str
    }
}

// MARK: - Helpers

private extension String {

    var detectedURL: URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let match = detector?.firstMatch(in: self, options: [], range: NSMakeRange(0, (self as NSString).length))
        return match?.url
    }

}
