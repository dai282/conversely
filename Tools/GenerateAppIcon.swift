import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let cs = CGColorSpaceCreateDeviceRGB()

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        colorSpace: cs,
        components: [
            CGFloat((hex >> 16) & 0xff) / 255,
            CGFloat((hex >> 8) & 0xff) / 255,
            CGFloat(hex & 0xff) / 255,
            alpha,
        ]
    )!
}

// Palette straight from DESIGN.md.
let deepBlue: UInt32 = 0x0d4582      // on-primary-container
let darkBlue: UInt32 = 0x001d3d
let primary: UInt32 = 0xb5cfff       // primary
let primaryContainer: UInt32 = 0x8ab4f8

guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { exit(1) }

// Background: diagonal gradient, lighter at top-left.
let gradient = CGGradient(
    colorsSpace: cs,
    colors: [color(deepBlue), color(darkBlue)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// Flip to top-down coordinates so the layout below reads like the design.
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

/// A speech bubble: rounded rect plus a tail triangle, as one path.
func bubble(rect: CGRect, radius: CGFloat, tail: [CGPoint]) -> CGPath {
    let path = CGMutablePath()
    path.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)
    path.move(to: tail[0])
    path.addLine(to: tail[1])
    path.addLine(to: tail[2])
    path.closeSubpath()
    return path
}

// Everything stays inside roughly x/y 170…820: iOS masks the icon to a
// rounded square, so anything pushed into a corner gets clipped.

// Upper-left bubble — the first speaker.
let bubbleA = bubble(
    rect: CGRect(x: 170, y: 250, width: 390, height: 260),
    radius: 70,
    tail: [CGPoint(x: 238, y: 496), CGPoint(x: 326, y: 496), CGPoint(x: 200, y: 598)]
)

// Lower-right bubble — the reply, overlapping to read as one exchange.
let bubbleB = bubble(
    rect: CGRect(x: 430, y: 460, width: 390, height: 260),
    radius: 70,
    tail: [CGPoint(x: 664, y: 706), CGPoint(x: 752, y: 706), CGPoint(x: 778, y: 796)]
)

ctx.addPath(bubbleA)
ctx.setFillColor(color(primary))
ctx.fillPath()

// Dark rim on the overlapping bubble so the two stay distinct at small sizes.
ctx.addPath(bubbleB)
ctx.setStrokeColor(color(darkBlue))
ctx.setLineWidth(40)
ctx.setLineJoin(.round)
ctx.strokePath()

ctx.addPath(bubbleB)
ctx.setFillColor(color(primaryContainer))
ctx.fillPath()

guard let image = ctx.makeImage() else { exit(1) }
let url = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
