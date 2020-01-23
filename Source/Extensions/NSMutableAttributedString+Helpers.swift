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

extension Sequence where Iterator.Element == NSMutableAttributedString? {
    /// Returns the concatenation of the non nil elements in this sequence.
    func join() -> NSMutableAttributedString {
        return reduce(NSMutableAttributedString()) { acc, next -> NSMutableAttributedString in
            guard let unwrapped = next else { return acc }
            acc.append(unwrapped)
            return acc
        }
    }
}

// MARK: - SIMPLE

extension NSMutableAttributedString {
    
    func prependBreak() {
        prepend("\n")
    }
    
    func appendBreak(attributes: [NSAttributedString.Key : Any]? = nil) {
        append("\n", attributes: attributes)
    }
    
    private func prepend(_ string: String) {
        insert(NSAttributedString(string: string), at: 0)
    }
    
    private func append(_ string: String, attributes: [NSAttributedString.Key : Any]? = nil) {
        append(NSAttributedString(string: string, attributes: attributes))
    }
    
    func addAttributes(_ attrs: DownStyle.Attributes?) {
        guard let attrs = attrs else { return }
        addAttributes(attrs, range: wholeRange)
    }
    
    func addAttribute(_ name: NSAttributedString.Key, value: Any) {
        addAttribute(name, value: value, range: wholeRange)
    }
}

// MARK: - COMPLEX

extension NSMutableAttributedString {
    
    /// Updates the value for the given attribute key in the given range
    /// with the return value of the given transform function.
    func map<A,B>(overKey key: NSAttributedString.Key, inRange range: NSRange, defaultValue: A? = nil, using transform: (A) -> B) {
        // collect exists values & ranges for the key
        var values = [(value: A, range: NSRange)]()
        enumerateAttribute(key, in: range, options: []) { value, range, _ in
            if let value = value as? A ?? defaultValue {
                values.append((value, range))
            }
        }
        // update the value with the transformation
        for (value, range) in values {
            addAttribute(key, value: transform(value), range: range)
        }
    }
    
    /// Updates the value for the given attribute key over the whole range
    /// with the return value of the given transform function.
    func map<A,B>(overKey key: NSAttributedString.Key, using transform: (A) -> B) {
        map(overKey: key, inRange: wholeRange, using: transform)
    }
    
    /// Italicizes the font while preserving existing symbolic traits.
    func italicize() {
        map(overKey: .font) { (font: UIFont) -> UIFont in
            return font.italic
        }
    }
    
    /// Boldens the font while preserving existing symbolic traits.
    func bolden() {
        map(overKey: .font) { (font: UIFont) -> UIFont in
            return font.withoutLightWeight.bold
        }
    }
    
    /// Boldens the font while preserving existing symbolic traits and updates
    /// the font size.
    func bolden(with size: CGFloat) {
        map(overKey: .font) { (font: UIFont) -> UIFont in
            return font.withoutLightWeight.withSize(size).bold
        }
    }
    
    /// Inserts the new markdown identifier into all existing identifiers.
    func add(markdownIdentifier: Markdown) {
        map(overKey: .markdown, inRange: wholeRange, defaultValue: Markdown.none) { (markdown: Markdown) -> Markdown in
            return markdown.union(markdownIdentifier)
        }
    }
}

// MARK: - Paragraph style

public extension NSMutableAttributedString {

    /// Replace all paragraphs' line break mode to byTruncatingTail for quoted message display in a limit size frame
    func paragraphTailTruncated() {
        map(overKey: .paragraphStyle) {
            (paragraphStyle: NSMutableParagraphStyle) -> NSMutableParagraphStyle in
            paragraphStyle.lineBreakMode = .byTruncatingTail
            return paragraphStyle
        }
    }
}

public extension NSAttributedString {
    
    var wholeRange: NSRange {
        return NSMakeRange(0, length)
    }
    
    /// Returns an array of ranges where the given markdown ID is exactly present.
    func ranges(of markdown: Markdown) -> [NSRange] {
        return ranges(of: markdown, inRange: wholeRange)
    }
    
    /// Returns an array of ranges where the given markdown ID is exactly present in
    /// over the given range.
    func ranges(of markdown: Markdown, inRange range: NSRange) -> [NSRange] {
        var result = [NSRange]()
        
        enumerateAttribute(.markdown, in: range, options: []) { val, range, _ in
            let currentMarkdown = (val as? Markdown) ?? .none
            if currentMarkdown == markdown { result.append(range) }
        }
        
        return result.unified
    }
    
    /// Returns an array of ranges where the given markdown ID is partially present.
    func ranges(containing markdown: Markdown) -> [NSRange] {
        return ranges(containing: markdown, inRange: wholeRange)
    }
    
    /// Returns an array of ranges where the given markdown ID is partially present in
    /// over the given range.
    func ranges(containing markdown: Markdown, inRange range: NSRange) -> [NSRange] {
        var result = [NSRange]()
        
        enumerateAttribute(.markdown, in: range, options: []) { val, range, _ in
            let currentMarkdown = (val as? Markdown) ?? .none
            
            // special case, b/c all markdown contains .none
            if markdown == .none {
                if currentMarkdown == .none { result.append(range) }
            }
            else if currentMarkdown.contains(markdown) {
                result.append(range)
            }
        }
        
        return result.unified
    }
    
    /// Returns an array of (value, range) pairs for the given attributed key, where
    /// value of the key is present at the range.
    func attributeRanges<T>(for key: NSAttributedString.Key, in range: NSRange) -> [(value: T, range: NSRange)] {
        var result = [(T, NSRange)]()
        enumerateAttribute(key, in: range, options: []) { val, attrRange, _ in
            guard let val = val as? T else { return }
            result.append((val, attrRange))
        }
        
        return result
    }
}
