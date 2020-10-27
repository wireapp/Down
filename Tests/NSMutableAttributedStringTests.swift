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

import XCTest
@testable import Down

class NSMutableAttributedStringTests: XCTestCase {
    
    var sut: NSMutableAttributedString!
    
    override func setUp() {
        super.setUp()
        sut = NSMutableAttributedString()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testThatItPrependsBreak() {
        // GIVEN
        sut = NSMutableAttributedString(string: "example")
        // WHEN
        sut.prependBreak()
        // THEN
        XCTAssertEqual("\nexample", sut.string)
    }
    
    func testThatItAppendsBreak() {
        // GIVEN
        sut = NSMutableAttributedString(string: "example")
        // WHEN
        sut.appendBreak()
        // THEN
        XCTAssertEqual("example\n", sut.string)
    }
    
    func testThatItAddsAttributesToWholeString() {
        // GIVEN
        sut = NSMutableAttributedString(string: "example")
        // WHEN
        sut.addAttributes([.markdown: Markdown.bold])
        // THEN
        var range = NSMakeRange(NSNotFound, 0)
        let result = sut.attribute(.markdown, at: 0, effectiveRange: &range) as? Markdown
        XCTAssertEqual(Markdown.bold, result)
        XCTAssertEqual(NSMakeRange(0, sut.length), range)
    }

    func testThatItPreservesExistingMarkownIds() {
        // // GIVEN
        sut = NSMutableAttributedString(string: "example")
        sut.addAttributes([.markdown: Markdown.bold])
        // WHEN
        sut.addAttributes([.markdown: Markdown.italic])
        // THEN
        var range = NSMakeRange(NSNotFound, 0)
        let result = sut.attribute(.markdown, at: 0, effectiveRange: &range) as? Markdown
        XCTAssertEqual([Markdown.bold, .italic], result)
        XCTAssertEqual(NSMakeRange(0, sut.length), range)
    }
    
    func testThatItItalicizes() {
        // GIVEN
        sut = NSMutableAttributedString(string: "example", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        // WHEN
        sut.italicize()
        // THEN
        var range = NSMakeRange(NSNotFound, 0)
        let font = sut.attribute(.font, at: 0, effectiveRange: &range) as? UIFont
        XCTAssertEqual(UIFont.italicSystemFont(ofSize: 16), font)
        XCTAssertEqual(NSMakeRange(0, sut.length), range)
    }
    
    func testThatItBoldens() {
        // GIVEN
        sut = NSMutableAttributedString(string: "example", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        // WHEN
        sut.bolden()
        // THEN
        var range = NSMakeRange(NSNotFound, 0)
        let font = sut.attribute(.font, at: 0, effectiveRange: &range) as? UIFont
        XCTAssertEqual(UIFont.boldSystemFont(ofSize: 16), font)
        XCTAssertEqual(NSMakeRange(0, sut.length), range)
    }
    
    func testThatItBoldensWithSize() {
        // GIVEN
        sut = NSMutableAttributedString(string: "example", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        // WHEN
        sut.bolden(with: 24)
        // THEN
        var range = NSMakeRange(NSNotFound, 0)
        let font = sut.attribute(.font, at: 0, effectiveRange: &range) as? UIFont
        XCTAssertEqual(UIFont.boldSystemFont(ofSize: 24), font)
    }
    
    func testThatItBoldensAndPreservesItalics() {
        // GIVEN
        sut = NSMutableAttributedString(string: "example", attributes: [.font: UIFont.italicSystemFont(ofSize: 16)])
        // WHEN
        sut.bolden()
        // THEN
        var range = NSMakeRange(NSNotFound, 0)
        let font = sut.attribute(.font, at: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.isBold)
        XCTAssertTrue(font!.isItalic)
        XCTAssertEqual(16, font!.pointSize)
        XCTAssertEqual(NSMakeRange(0, sut.length), range)
    }
    
    func testThatItAddsMarkdownIdentifier() {
        // GIVEN
        sut = NSMutableAttributedString(string: "example", attributes: [.markdown: Markdown.bold])
        // WHEN
        sut.add(markdownIdentifier: .italic)
        // THEN
        var range = NSMakeRange(NSNotFound, 0)
        let result = sut.attribute(.markdown, at: 0, effectiveRange: &range) as? Markdown
        XCTAssertEqual([.bold, .italic], result)
        XCTAssertEqual(NSMakeRange(0, sut.length), range)
    }
    
    func testThatItReturnsRangesOfMarkdown() {
        // GIVEN
        let bold = [NSAttributedString.Key.markdown: Markdown.bold]
        sut.append(NSAttributedString(string: "normal"))
        sut.append(NSAttributedString(string: "bold", attributes: bold))
        sut.append(NSAttributedString(string: "normal"))
        sut.append(NSAttributedString(string: "bold", attributes: bold))
        sut.append(NSAttributedString(string: "normal"))
        sut.append(NSAttributedString(string: "bold", attributes: bold))
        sut.append(NSAttributedString(string: "normal"))
        // WHEN
        let result = sut.ranges(of: .bold)
        // THEN
        XCTAssertEqual(3, result.count)
        XCTAssertEqual(NSMakeRange(6, 4), result[0])
        XCTAssertEqual(NSMakeRange(16, 4), result[1])
        XCTAssertEqual(NSMakeRange(26, 4), result[2])
    }
    
    func testThatItReturnsRangesContainingMarkdown() {
        // GIVEN
        let bold = [NSAttributedString.Key.markdown: Markdown.bold]
        let h1Bold = [NSAttributedString.Key.markdown: Markdown([.h1, .bold])]
        let boldItalic = [NSAttributedString.Key.markdown: Markdown([.bold, .italic])]
        let italic = [NSAttributedString.Key.markdown: Markdown.italic]
        sut.append(NSAttributedString(string: "normal"))
        sut.append(NSAttributedString(string: "bold", attributes: bold))
        sut.append(NSAttributedString(string: "h1 bold", attributes: h1Bold))
        sut.append(NSAttributedString(string: "bold", attributes: bold))
        sut.append(NSAttributedString(string: "normal"))
        sut.append(NSAttributedString(string: "bolditalic", attributes: boldItalic))
        sut.append(NSAttributedString(string: "normal"))
        sut.append(NSAttributedString(string: "italic", attributes: italic))
        // WHEN
        let boldResult = sut.ranges(containing: .bold)
        let italicResult = sut.ranges(containing: .italic)
        // THEN
        XCTAssertEqual(2, boldResult.count)
        XCTAssertEqual(NSMakeRange(6, 15), boldResult[0])
        XCTAssertEqual(NSMakeRange(27, 10), boldResult[1])
        XCTAssertEqual(2, italicResult.count)
        XCTAssertEqual(NSMakeRange(27, 10), italicResult[0])
        XCTAssertEqual(NSMakeRange(43, 6), italicResult[1])
    }

    func testThatItChangesParagraphLineBreakMode() {
        // GIVEN
        let down = Down(markdownString: """
        # Summary of Today’s Meeting Upcoming due dates:
        - Jan 4, final copy in review
        - Jan 15, final layout with copy
        - Jan 20, release on website
        """)
        // WHEN
        let style = DownStyle()
        let attributedString = try! down.toAttributedString(using: style)
        let sut = NSMutableAttributedString(attributedString: attributedString)

        // original line break mode is line wrap

        checkAllparagraphStyle(lineBreakMode: .byWordWrapping)

        // WHEN
        sut.paragraphTailTruncated()

        // THEN
        checkAllparagraphStyle(lineBreakMode: .byTruncatingTail)
    }

    func checkAllparagraphStyle(lineBreakMode: NSLineBreakMode, file: StaticString = #file, line: UInt = #line) {
        sut.enumerateAttributes(in: NSRange(0..<sut.length), options: []) { (dict, range, _) in
            if let paragraphStyle = dict[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle{
                XCTAssertEqual(paragraphStyle.lineBreakMode, .byWordWrapping, file: file, line: line)
            }
        }
    }
}
