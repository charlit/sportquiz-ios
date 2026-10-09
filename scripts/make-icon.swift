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

// Ballon de foot : panneaux blancs, pentagones noirs (motif classique vu de face), légèrement ombré.
let c = CGPoint(x: 512, y: 512), R: CGFloat = 400
func pt(_ deg: CGFloat, _ d: CGFloat, from o: CGPoint = c) -> CGPoint {
    CGPoint(x: o.x + d * cos(deg * .pi / 180), y: o.y + d * sin(deg * .pi / 180))
}
// Ombre portée sous le ballon.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: rgb(0x000000, 0.45))
ctx.setFillColor(rgb(0xffffff)); ctx.fillEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R))
ctx.restoreGState()

ctx.saveGState()
ctx.addEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R)); ctx.clip()
let shade = CGGradient(colorsSpace: nil, colors: [rgb(0xffffff), rgb(0xe6e9ec), rgb(0xa9b0b6)] as CFArray, locations: [0, 0.6, 1])!
ctx.drawRadialGradient(shade, startCenter: pt(120, 0.35 * R), startRadius: 0, endCenter: c, endRadius: R, options: [])

let r0 = 0.30 * R, r1 = 0.27 * R, seam = 0.60 * R          // pentagone central, pentagones extérieurs, fin des coutures
let center = (0..<5).map { pt(90 + 72 * CGFloat($0), r0) }
var outer: [[CGPoint]] = []                                     // sommets de chaque pentagone extérieur, le 1er tourné vers le centre
for k in 0..<5 {
    let a = 90 + 72 * CGFloat(k), o = pt(a, seam + r1)
    outer.append((0..<5).map { pt(a + 180 + 72 * CGFloat($0), r1, from: o) })
}
let ink = rgb(0x15191d)
func polygon(_ p: [CGPoint]) { ctx.move(to: p[0]); p.dropFirst().forEach { ctx.addLine(to: $0) }; ctx.closePath() }
ctx.setFillColor(ink)
polygon(center); ctx.fillPath()
outer.forEach { polygon($0); ctx.fillPath() }
// Coutures : du pentagone central vers chaque pentagone extérieur, entre pentagones voisins, puis vers le bord.
ctx.setStrokeColor(rgb(0x3a4148)); ctx.setLineWidth(10); ctx.setLineCap(.round)
for k in 0..<5 {
    let p = outer[k], next = outer[(k + 1) % 5]
    ctx.move(to: center[k]); ctx.addLine(to: p[0])
    ctx.move(to: p[4]); ctx.addLine(to: next[1])
    for v in [p[2], p[3]] { ctx.move(to: v); ctx.addLine(to: pt(atan2(v.y - c.y, v.x - c.x) * 180 / .pi, R * 1.2)) }
}
ctx.strokePath()
ctx.restoreGState()
ctx.setStrokeColor(rgb(0x0b1d14, 0.6)); ctx.setLineWidth(8)
ctx.strokeEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R))

// « ? » jaune (couleur d'accent du quiz) cerné de vert foncé, par-dessus le ballon.
let system = CTFontCreateUIFontForLanguage(.system, 600, nil)!
let font = CTFontCreateWithFontDescriptor(CTFontDescriptorCreateCopyWithAttributes(CTFontCopyFontDescriptor(system), [
    kCTFontTraitsAttribute: [kCTFontWeightTrait: 0.62],   // Heavy
] as CFDictionary), 600, nil)
func mark(_ extra: [NSAttributedString.Key: Any]) -> CTLine {
    var attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): font]
    extra.forEach { attrs[$0] = $1 }
    return CTLineCreateWithAttributedString(NSAttributedString(string: "?", attributes: attrs))
}
let outline = mark([NSAttributedString.Key(kCTStrokeColorAttributeName as String): rgb(0x0b1d14),
                    NSAttributedString.Key(kCTStrokeWidthAttributeName as String): 14])
let fill = mark([NSAttributedString.Key(kCTForegroundColorAttributeName as String): rgb(0xffd23f)])
let b = CTLineGetBoundsWithOptions(fill, .useGlyphPathBounds)
ctx.textPosition = CGPoint(x: 512 - b.midX, y: 512 - b.midY)
ctx.setLineJoin(.round)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: rgb(0x000000, 0.5))
CTLineDraw(outline, ctx)
ctx.restoreGState()
ctx.textPosition = CGPoint(x: 512 - b.midX, y: 512 - b.midY)
CTLineDraw(fill, ctx)

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil); CGImageDestinationFinalize(dest)
