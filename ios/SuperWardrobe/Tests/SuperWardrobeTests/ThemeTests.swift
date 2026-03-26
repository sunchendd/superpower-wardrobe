import XCTest
import SwiftUI
@testable import SuperWardrobe

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class ThemeTests: XCTestCase {
    func testHexColorParsingSupportsCommonFormats() {
        assertRGBA(Color(hex: "#ABC"), red: 0.6667, green: 0.7333, blue: 0.8, alpha: 1.0)
        assertRGBA(Color(hex: "#112233"), red: 0.0667, green: 0.1333, blue: 0.2, alpha: 1.0)
        assertRGBA(Color(hex: "#80112233"), red: 0.0667, green: 0.1333, blue: 0.2, alpha: 0.502)
    }

    func testInvalidHexFallsBackToBlack() {
        assertRGBA(Color(hex: "not-a-color"), red: 0, green: 0, blue: 0, alpha: 1)
    }

    private func assertRGBA(
        _ color: Color,
        red: Double,
        green: Double,
        blue: Double,
        alpha: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        #if canImport(UIKit)
        let platformColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        XCTAssertTrue(platformColor.getRed(&r, green: &g, blue: &b, alpha: &a), file: file, line: line)
        XCTAssertEqual(Double(r), red, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(Double(g), green, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(Double(b), blue, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(Double(a), alpha, accuracy: 0.01, file: file, line: line)
        #elseif canImport(AppKit)
        let platformColor = NSColor(color)
        let srgb = platformColor.usingColorSpace(.sRGB) ?? platformColor
        XCTAssertEqual(Double(srgb.redComponent), red, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(Double(srgb.greenComponent), green, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(Double(srgb.blueComponent), blue, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(Double(srgb.alphaComponent), alpha, accuracy: 0.01, file: file, line: line)
        #else
        XCTFail("No supported platform color bridge is available.", file: file, line: line)
        #endif
    }
}
