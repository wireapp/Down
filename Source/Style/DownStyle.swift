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


@objc public class DownStyle: NSObject {
    
    public typealias Attributes = [NSAttributedString.Key : Any]
    
    @objc public var baseFont = UIFont.systemFont(ofSize: 17)
    @objc public var baseFontColor = UIColor.black
    @objc public var baseParagraphStyle = NSParagraphStyle.default.with(topSpacing: 8, bottomSpacing: 8)
    
    public var codeFont = UIFont(name: "Menlo", size: 17) ?? UIFont.systemFont(ofSize: 17)
    public var codeColor: UIColor? = UIColor.darkGray
    
    public var headerParagraphStyle = NSParagraphStyle.default.with(topSpacing: 8, bottomSpacing: 8)
    
    public var h1Color: UIColor?
    public var h1Size: CGFloat = 27
    
    public var h2Color: UIColor?
    public var h2Size: CGFloat = 24
    
    public var h3Color: UIColor?
    public var h3Size: CGFloat = 20
    
    public var quoteColor: UIColor? = .gray
    public var quoteParagraphStyle: NSParagraphStyle? = NSParagraphStyle.default.indentedBy(points: 24)
        
    /// The amount of space between the prefix and content of a list item
    public var listItemPrefixSpacing: CGFloat = 8
    
    @objc public var listItemPrefixColor: UIColor?
    
    /// The minimum prefix width is used to determine the alignment rule for
    /// list items. It will always have enough space to fit 2-digit prefixes.
    lazy var minListPrefixWidth: CGFloat = {
        return self.widthOfListPrefix("99.")
    }()
    
    /// Returns the width of the given prefix (in points) after applying its style.
    func widthOfListPrefix(_ prefix: String) -> CGFloat {
        let attrPrefix = NSAttributedString(string: prefix, attributes: self.listPrefixAttributes)
        return attrPrefix.size().width
    }
    
    var defaultAttributes: Attributes {
        return [.markdown: Markdown.none,
                .font: baseFont,
                .foregroundColor: baseFontColor,
                .paragraphStyle: baseParagraphStyle,
        ]
    }
    
    var boldAttributes: Attributes {
        return [.markdown: Markdown.bold]
    }
    
    var italicAttributes: Attributes {
        return [.markdown: Markdown.italic]
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
    
    var listPrefixAttributes: Attributes {
        let font = UIFont.monospacedDigitSystemFont(ofSize: baseFont.pointSize, weight: .light)
        return [.font: font,
                .foregroundColor: listItemPrefixColor ?? baseFontColor
        ]
    }

    var listTabAttributes: Attributes {
        let font = UIFont.monospacedDigitSystemFont(ofSize: baseFont.pointSize, weight: .light)
        return [.font: font]
    }

    var h1Attributes: Attributes {
        return [.markdown: Markdown.h1,
                .foregroundColor: h1Color ?? baseFontColor,
                .paragraphStyle: headerParagraphStyle
        ]
    }
    
    var h2Attributes: Attributes {
        return [.markdown: Markdown.h2,
                .foregroundColor: h2Color ?? baseFontColor,
                .paragraphStyle: headerParagraphStyle
        ]
    }
    
    var h3Attributes: Attributes {
        return [.markdown: Markdown.h3,
                .foregroundColor: h3Color ?? baseFontColor,
                .paragraphStyle: headerParagraphStyle
        ]
    }
    
    public func headerSize(for markdown: Markdown) -> CGFloat? {
        switch markdown {
        case .h1:   return h1Size
        case .h2:   return h2Size
        case .h3:   return h3Size
        default:    return nil
        }
    }
    
    public func headerColor(for markdown: Markdown) -> UIColor? {
        switch markdown {
        case .h1:   return h1Color
        case .h2:   return h2Color
        case .h3:   return h3Color
        default:    return nil
        }
    }
    
    func headerSize(for level: Int) -> CGFloat {
        switch level {
        case 1:  return h1Size
        case 2:  return h2Size
        default: return h3Size
        }
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
            return nil
            
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

        case .paragraph(_):
            return defaultAttributes

        case .document(_), .thematicBreak:
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
            NSTextTab(textAlignment: $0.alignment, location: $0.location + points)
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


public extension UIFont {
    
    /// A copy of the font without the light weight.
    public var withoutLightWeight: UIFont {
        guard fontName.contains("Light") else { return self }
        guard let name = fontName.split(separator: "-").first else { return self }
        let fontDesc = UIFontDescriptor(fontAttributes: [.name: name])
        // create the font again
        let font = UIFont(descriptor: fontDesc, size: pointSize)
        // preserve italic trait
        return isItalic ? font.italic : font
    }
    
    // MARK: - Trait Querying
    
    public var isBold: Bool {
        return contains(.traitBold)
    }
    
    public var isItalic: Bool {
        return contains(.traitItalic)
    }
    
    private func contains(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        return fontDescriptor.symbolicTraits.contains(trait)
    }
    
    // MARK: - Set Traits
    
    public var bold: UIFont {
        return self.with(.traitBold)
    }
    
    public var italic: UIFont {
        return self.with(.traitItalic)
    }
    
    /// Returns a copy of the font with the added symbolic trait.
    private func with(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard !contains(trait) else { return self }
        var traits = fontDescriptor.symbolicTraits
        traits.insert(trait)
        guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        // size 0 means the size remains the same as before
        return UIFont(descriptor: newDescriptor, size: 0)
    }
}

