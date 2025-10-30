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
#if canImport(UIKit)
import UIKit

public typealias Font = UIFont
public typealias Color = UIColor
#else
import AppKit

public typealias Font = NSFont
public typealias Color = NSColor
#endif


@objc open class DownStyle: NSObject {
    
    public typealias Attributes = [NSAttributedString.Key : Any]
    
    @objc open var baseFont = Font.systemFont(ofSize: 17)
    @objc open var baseFontColor = Color.black
    @objc open var baseParagraphStyle = NSParagraphStyle.default.with(topSpacing: 8, bottomSpacing: 8)
    
    open var codeFont = Font(name: "Menlo", size: 17) ?? Font.systemFont(ofSize: 17)
    open var codeColor: Color? = Color.darkGray
    
    open var headerParagraphStyle = NSParagraphStyle.default.with(topSpacing: 8, bottomSpacing: 8)
    
    open var h1Color: Color?
    open var h1Size: CGFloat = 27
    
    open var h2Color: Color?
    open var h2Size: CGFloat = 24
    
    open var h3Color: Color?
    open var h3Size: CGFloat = 20
    
    open var quoteColor: Color? = .gray
    open var quoteParagraphStyle: NSParagraphStyle? = NSParagraphStyle.default.indentedBy(points: 24)

    /// If true, then only links with valid urls will be rendered. Invalid links
    /// will be rendered as raw markdown.
    open var renderOnlyValidLinks = true
        
    /// The amount of space between the prefix and content of a list item
    open var listItemPrefixSpacing: CGFloat = 8
    
    @objc open var listItemPrefixColor: Color?
    
    /// The minimum prefix width is used to determine the alignment rule for
    /// list items. It will always have enough space to fit 2-digit prefixes.
    lazy var minListPrefixWidth: CGFloat = {
        return self.widthOfListPrefix("99.")
    }()
    
    /// Returns the width of the given prefix (in points) after applying its style.
    open func widthOfListPrefix(_ prefix: String) -> CGFloat {
        let attrPrefix = NSAttributedString(string: prefix, attributes: self.listPrefixAttributes)
        return attrPrefix.size().width
    }
    
    open var defaultAttributes: Attributes {
        return [.markdown: Markdown.none,
                .font: baseFont,
                .foregroundColor: baseFontColor,
                .paragraphStyle: baseParagraphStyle,
        ]
    }
    
    open var boldAttributes: Attributes {
        return [.markdown: Markdown.bold]
    }
    
    open var italicAttributes: Attributes {
        return [.markdown: Markdown.italic]
    }
    
    open var codeAttributes: Attributes {
        return [.markdown: Markdown.code,
                .font: codeFont,
                .foregroundColor: codeColor ?? baseFontColor,
        ]
    }
    
    open var quoteAttributes: Attributes {
        return [.markdown: Markdown.quote,
                .foregroundColor: quoteColor ?? baseFontColor,
                .paragraphStyle: quoteParagraphStyle ?? baseParagraphStyle,
        ]
    }
    
    open var listPrefixAttributes: Attributes {
        let font = Font.monospacedDigitSystemFont(ofSize: baseFont.pointSize, weight: .light)
        return [.font: font,
                .foregroundColor: listItemPrefixColor ?? baseFontColor
        ]
    }

    open var h1Attributes: Attributes {
        return [.markdown: Markdown.h1,
                .foregroundColor: h1Color ?? baseFontColor,
                .paragraphStyle: headerParagraphStyle
        ]
    }
    
    open var h2Attributes: Attributes {
        return [.markdown: Markdown.h2,
                .foregroundColor: h2Color ?? baseFontColor,
                .paragraphStyle: headerParagraphStyle
        ]
    }
    
    open var h3Attributes: Attributes {
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
    
    public func headerColor(for markdown: Markdown) -> Color? {
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
    
    open func attributes(for block: Block) -> Attributes? {
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
    
    open func attributes(for inline: Inline) -> Attributes? {
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


public extension Font {
    
    /// A copy of the font without the light weight.
    var withoutLightWeight: Font {
        guard fontName.contains("Light") else { return self }
        
        // WORKAROUND: remove font weight by re-creating the font using the system font.
        // This will break if you use Down with a custom font. We should find a better
        // way to solve this problem, but that probably requires architectural changes.
        let font = Font.systemFont(ofSize: pointSize)
        
        // preserve italic trait
        return isItalic ? font.italic : font
    }
    
    // MARK: - Trait Querying
    
    var isBold: Bool {
        #if canImport(UIKit)
        return contains(.traitBold)
        #else
        return contains(.bold)
        #endif
    }
    
    var isItalic: Bool {
        #if canImport(UIKit)
        return contains(.traitItalic)
        #else
        return contains(.italic)
        #endif
    }
    
    #if canImport(UIKit)
    private func contains(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        return fontDescriptor.symbolicTraits.contains(trait)
    }
    #else
    private func contains(_ trait: NSFontDescriptor.SymbolicTraits) -> Bool {
        return fontDescriptor.symbolicTraits.rawValue & trait.rawValue != 0
    }
    #endif
    
    // MARK: - Set Traits
    
    var bold: Font {
        #if canImport(UIKit)
        return self.with(.traitBold)
        #else
        return self.with(.bold)
        #endif
    }
    
    var italic: Font {
        #if canImport(UIKit)
        return self.with(.traitItalic)
        #else
        return self.with(.italic)
        #endif
    }
    
    /// Returns a copy of the font with the added symbolic trait.
    #if canImport(UIKit)
    private func with(_ trait: UIFontDescriptor.SymbolicTraits) -> Font {
        guard !contains(trait) else { return self }
        var traits = fontDescriptor.symbolicTraits
        traits.insert(trait)
        guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return Font(descriptor: newDescriptor, size: 0)
    }
    #else
    private func with(_ trait: NSFontDescriptor.SymbolicTraits) -> Font {
        guard !contains(trait) else { return self }
        let traits = NSFontDescriptor.SymbolicTraits(rawValue: fontDescriptor.symbolicTraits.rawValue | trait.rawValue)
        let newDescriptor = fontDescriptor.withSymbolicTraits(traits)
        return Font(descriptor: newDescriptor, size: 0) ?? self
    }
    #endif
}

