// Régénère l'icône : swift scripts/make-icon.swift SportQuizApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
import CoreGraphics
import CoreText
import ImageIO
import Foundation
import UniformTypeIdentifiers

let S = 1024
func rgb(_ h: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(h >> 16 & 0xff) / 255, green: CGFloat(h >> 8 & 0xff) / 255, blue: CGFloat(h & 0xff) / 255, alpha: a)
}
// Pas de canal alpha : iOS exige une icône opaque.
let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// Même fond que le quiz : dégradé vert « pelouse » éclairé par le haut.
let bg = CGGradient(colorsSpace: nil, colors: [rgb(0x1d4a31), rgb(0x0b1d14)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(bg, startCenter: CGPoint(x: 512, y: 1024), startRadius: 0,
                       endCenter: CGPoint(x: 512, y: 1024), endRadius: 1100, options: .drawsAfterEndLocation)

// Lignes du terrain : rond central et ligne médiane.
ctx.setStrokeColor(rgb(0xffffff, 0.12)); ctx.setLineWidth(18)
ctx.strokeEllipse(in: CGRect(x: 512 - 400, y: 512 - 400, width: 800, height: 800))
ctx.move(to: CGPoint(x: 0, y: 512)); ctx.addLine(to: CGPoint(x: 1024, y: 512)); ctx.strokePath()

// Pastille jaune (couleur d'accent du quiz) avec un « ? » vert foncé.
ctx.setFillColor(rgb(0xffd23f)); ctx.fillEllipse(in: CGRect(x: 512 - 290, y: 512 - 290, width: 580, height: 580))
let system = CTFontCreateUIFontForLanguage(.system, 440, nil)!
let font = CTFontCreateWithFontDescriptor(CTFontDescriptorCreateCopyWithAttributes(CTFontCopyFontDescriptor(system), [
    kCTFontTraitsAttribute: [kCTFontWeightTrait: 0.62],   // Heavy
] as CFDictionary), 440, nil)
let text = NSAttributedString(string: "?", attributes: [
    NSAttributedString.Key(kCTFontAttributeName as String): font,
    NSAttributedString.Key(kCTForegroundColorAttributeName as String): rgb(0x0b1d14),
])
let line = CTLineCreateWithAttributedString(text)
let b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
ctx.textPosition = CGPoint(x: 512 - b.midX, y: 512 - b.midY)
CTLineDraw(line, ctx)

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil); CGImageDestinationFinalize(dest)
