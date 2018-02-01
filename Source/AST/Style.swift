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

import Foundation
import UIKit

// TODO: check that code font is actually rendering
// what happens with code in header?

/// Use as values for `NSAttributedStringKey.markdown` to be able to easily
/// identify ranges of markdown in an `NSAttributedString`.
struct Markdown: OptionSet {
    
    let rawValue: Int
    
    static let none     = Markdown(rawValue: 0)
    static let header   = Markdown(rawValue: 1 << 0)
    static let bold     = Markdown(rawValue: 1 << 1)
    static let italic   = Markdown(rawValue: 1 << 2)
    static let code     = Markdown(rawValue: 1 << 3)
    static let list     = Markdown(rawValue: 1 << 4)
    static let quote    = Markdown(rawValue: 1 << 5)
}

extension NSAttributedStringKey {
    static let markdown = NSAttributedStringKey.init(rawValue: "markdown")
}

public struct Style {
    
    public static var `default`: Style { return Style() }
    
    typealias Attributes = [NSAttributedStringKey : Any]
    
    // base attributes - these will be used for normal text and will be manipulated
    // for bold, italic and code etc.
    
    // change this to system font size
    public var baseFont = UIFont.systemFont(ofSize: 17)
    public var baseFontColor = UIColor.black
    public var baseParagraphStyle = NSParagraphStyle.default.with(topSpacing: 8, bottomSpacing: 8)
    
    // bold attributes
    public var boldColor: UIColor?
    
    // italic attributes
    public var italicColor: UIColor?
    
    // code attributes
    public var codeFont = UIFont(name: "Menlo", size: 17)!
    public var codeColor: UIColor? = UIColor.darkGray
    
    // header attributes
    public var h1Color: UIColor? = #colorLiteral(red: 0.9529746175, green: 0.3621142805, blue: 0.3340556622, alpha: 1)
    public var h1Size: CGFloat = 27
    
    public var h2Color: UIColor? = #colorLiteral(red: 0.9529746175, green: 0.3621142805, blue: 0.3340556622, alpha: 1)
    public var h2Size: CGFloat = 24
    
    public var h3Color: UIColor? = #colorLiteral(red: 0.9529746175, green: 0.3621142805, blue: 0.3340556622, alpha: 1)
    public var h3Size: CGFloat = 20
    
    // quote attributes
    public var quoteColor: UIColor? = .gray
    public var quoteParagraphStyle: NSParagraphStyle? = NSParagraphStyle.default.indentedBy(points: 24)
    
    // list attributes
    
    /// The amount the list is indented from the leading margin
    public var listIndentation: CGFloat = 16
    /// the amount of space between the prefix and content of a list item
    public var listItemPrefixSpacing: CGFloat = 8
    
    var defaultAttributes: Attributes {
        return [.markdown: Markdown.none,
                .font: baseFont,
                .foregroundColor: baseFontColor,
                .paragraphStyle: baseParagraphStyle,
        ]
    }
    
    var boldAttributes: Attributes {
        return [.markdown: Markdown.bold,
                .foregroundColor: boldColor ?? baseFontColor
        ]
    }
    
    var italicAttributes: Attributes {
        return [.markdown: Markdown.italic,
                .foregroundColor: italicColor ?? baseFontColor
        ]
    }
    
    var codeAttributes: Attributes {
        return [.markdown: Markdown.code,
                .font: codeFont,
                .foregroundColor: codeColor ?? baseFontColor,
        ]
    }
    
    var quoteAttributes: Attributes {
        return [.markdown: Markdown.quote,
                .foregroundColor: quoteColor ?? baseFontColor,
                .paragraphStyle: quoteParagraphStyle ?? baseParagraphStyle,
        ]
    }
    
    var listAttributes: Attributes {
        return [.markdown: Markdown.list]
    }
    
    var h1Attributes: Attributes {
        return [.markdown: Markdown.header,
                .foregroundColor: h1Color ?? baseFontColor
        ]
    }
    
    var h2Attributes: Attributes {
        return [.markdown: Markdown.header,
                .foregroundColor: h2Color ?? baseFontColor
        ]
    }
    
    var h3Attributes: Attributes {
        return [.markdown: Markdown.header,
                .foregroundColor: h3Color ?? baseFontColor
        ]
    }
    
    func headerSize(for level: Int) -> CGFloat {
        switch level {
        case 1:  return h1Size
        case 2:  return h2Size
        default: return h3Size
        }
    }
    
    func listParagraphStyle(with prefixWidth: CGFloat) -> NSParagraphStyle {
        return NSParagraphStyle
            .default
            .with(topSpacing: 4, bottomSpacing: 4)
            .with(tabStopOffset: prefixWidth + listItemPrefixSpacing)
            .indentedBy(points: listIndentation)
    }
    
    func attributes(for renderable: Renderable) -> Attributes? {
        if renderable is Block  { return attributes(for: renderable as! Block) }
        if renderable is Inline { return attributes(for: renderable as! Inline) }
        return nil
    }
    
    private func attributes(for block: Block) -> Attributes? {
        switch block {
        case .blockQuote(_):
            return quoteAttributes
            
        case .list(_, _):
            return listAttributes
            
        case .listItem(_, _):
            return nil
            
        case .codeBlock(_), .htmlBlock(_):
            return codeAttributes
            
        case .customBlock(_):
            return defaultAttributes
            
        case .heading(_, let level):
            switch level {
            case 1:  return h1Attributes
            case 2:  return h2Attributes
            default: return h3Attributes
            }
            
        case .document(_), .paragraph(_), .thematicBreak:
            return nil
        }
    }
    
    private func attributes(for inline: Inline) -> Attributes? {
        switch inline {
        case .text(_), .custom(_):
            return defaultAttributes
            
        case .softBreak, .lineBreak:
            return nil
            
        case .code(_), .html(_):
            return codeAttributes
            
        case .emphasis(_):
            return italicAttributes
            
        case .strong(_):
            return boldAttributes
            
        case .link(_), .image(_):
            return nil
        }
    }
    
}



extension NSParagraphStyle {
    
    func with(topSpacing: CGFloat, bottomSpacing: CGFloat) -> NSParagraphStyle {
        let copy = mutableCopy() as! NSMutableParagraphStyle
        copy.paragraphSpacingBefore = topSpacing
        copy.paragraphSpacing = bottomSpacing
        return copy as NSParagraphStyle
    }
    
    /// Indents the current paragraph style by the given number of points.
    func indentedBy(points: CGFloat) -> NSParagraphStyle {
        let copy = mutableCopy() as! NSMutableParagraphStyle
        copy.firstLineHeadIndent += points
        copy.headIndent += points
        copy.tabStops = copy.tabStops.map {
            NSTextTab(textAlignment: .left, location: $0.location + points)
        }
        return copy as NSParagraphStyle
    }
    
    /// Shifts the tabstop offset
    func with(tabStopOffset offset: CGFloat) -> NSParagraphStyle {
        let copy = mutableCopy() as! NSMutableParagraphStyle
        copy.headIndent = offset
        copy.tabStops = [NSTextTab(textAlignment: .left, location: offset)]
        return copy as NSParagraphStyle
    }
}


// TODO: check whether just adding traits works for all fonts?

extension UIFont {
    
    // MARK: - Trait Querying
    
    var isBold: Bool {
        return contains(.traitBold)
    }
    
    var isItalic: Bool {
        return contains(.traitItalic)
    }
    
    var isMonospace: Bool {
        return contains(.traitMonoSpace)
    }
    
    private func contains(_ trait: UIFontDescriptorSymbolicTraits) -> Bool {
        return fontDescriptor.symbolicTraits.contains(trait)
    }
    
    // MARK: - Set Traits
    
    var bold: UIFont {
        return self.with(.traitBold)
    }
    
    var italic: UIFont {
        return self.with(.traitItalic)
    }
    
    var monospace: UIFont {
        return self.with(.traitMonoSpace)
    }
    
    /// Returns a copy of the font with the added symbolic trait.
    private func with(_ trait: UIFontDescriptorSymbolicTraits) -> UIFont {
        guard !contains(trait) else { return self }
        var traits = fontDescriptor.symbolicTraits
        traits.insert(trait)
        // FIXME: perhaps no good!
        guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        // size 0 means the size remains the same as before
        return UIFont(descriptor: newDescriptor, size: 0)
    }
}
