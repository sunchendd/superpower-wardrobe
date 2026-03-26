import XCTest
import UIKit
@testable import SuperWardrobe

final class ImageStorageTests: XCTestCase {
    func testCompressedJPEGDataRespectsMaximumDimension() throws {
        let image = makeImage(size: CGSize(width: 2000, height: 1000))

        let data = ImageStorage.compressedJPEGData(from: image, maxDimension: 1024, quality: 0.8)

        XCTAssertNotNil(data)
        let decoded = try XCTUnwrap(data.flatMap(UIImage.init(data:)))
        XCTAssertLessThanOrEqual(decoded.size.width, 1024)
        XCTAssertLessThanOrEqual(decoded.size.height, 1024)
        XCTAssertEqual(decoded.size.width / decoded.size.height, 2.0, accuracy: 0.05)
    }

    func testThumbnailProducesSmallerImage() throws {
        let image = makeImage(size: CGSize(width: 1800, height: 900))
        let data = try XCTUnwrap(ImageStorage.compressedJPEGData(from: image, maxDimension: 1024))

        let thumbnail = try XCTUnwrap(ImageStorage.thumbnail(from: data, maxDimension: 256))

        XCTAssertLessThanOrEqual(thumbnail.size.width, 256)
        XCTAssertLessThanOrEqual(thumbnail.size.height, 256)
        XCTAssertEqual(thumbnail.size.width / thumbnail.size.height, 2.0, accuracy: 0.05)
    }

    private func makeImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
