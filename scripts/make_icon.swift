import AppKit
import CoreGraphics
import ImageIO

// Draws the app icon (1024 x 1024). Usage: swift make_icon.swift <output.png> <letter>
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let label = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "A"
let side = 1024

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
    fatalError("no color space")
}

// An app icon must not be transparent, so this bitmap has no alpha channel.
guard let cg = CGContext(
    data: nil,
    width: side,
    height: side,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("no context")
}

cg.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
cg.fill(CGRect(x: 0, y: 0, width: side, height: side))

let graphics = NSGraphicsContext(cgContext: cg, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics

let accent = NSColor(srgbRed: 0.30, green: 0.55, blue: 1.00, alpha: 1)
let fontSize: CGFloat = label.count <= 1 ? 560 : 400
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: fontSize, weight: .heavy),
    .foregroundColor: accent
]
let text = label as NSString
let textSize = text.size(withAttributes: attributes)
text.draw(
    at: NSPoint(
        x: (CGFloat(side) - textSize.width) / 2,
        y: (CGFloat(side) - textSize.height) / 2
    ),
    withAttributes: attributes
)

NSGraphicsContext.restoreGraphicsState()

guard let image = cg.makeImage() else {
    fatalError("no image")
}

let url = URL(fileURLWithPath: output)
guard let destination = CGImageDestinationCreateWithURL(
    url as CFURL, "public.png" as CFString, 1, nil
) else {
    fatalError("no destination")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("write failed")
}
print("Icon saved: \(output)")