// Images des succès Game Center (512×512, opaques) : le dessin Twemoji du badge (twemoji/<id>.svg, licence CC-BY 4.0)
// sur un médaillon doré. Pas d'emoji Apple : Apple interdit de les reprendre en image (règles 4.5.6 et 5.2.5).
// swift scripts/make-achievements.swift AppStore/succes   (lit succes.json et twemoji/, écrit <id>.png)
import AppKit

let dir = URL(fileURLWithPath: CommandLine.arguments[1])
let list = try! JSONSerialization.jsonObject(with: Data(contentsOf: dir.appendingPathComponent("succes.json"))) as! [[String: Any]]
let size = 512
for item in list {
    let id = item["id"] as! String, emoji = item["emoji"] as! String
    // Contexte RGB sans alpha : Apple refuse la transparence dans les images de succès
    let cg = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)
    let s = CGFloat(size)
    NSGradient(colors: [NSColor(red: 0.10, green: 0.17, blue: 0.31, alpha: 1), NSColor(red: 0.04, green: 0.07, blue: 0.13, alpha: 1)])!
        .draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -90)
    let ring = NSBezierPath(ovalIn: NSRect(x: 36, y: 36, width: s - 72, height: s - 72))
    NSGradient(colors: [NSColor(red: 1, green: 0.84, blue: 0.35, alpha: 1), NSColor(red: 0.85, green: 0.55, blue: 0.10, alpha: 1)])!.draw(in: ring, angle: -90)
    let disc = NSBezierPath(ovalIn: NSRect(x: 58, y: 58, width: s - 116, height: s - 116))
    NSGradient(colors: [NSColor(red: 0.16, green: 0.24, blue: 0.40, alpha: 1), NSColor(red: 0.07, green: 0.11, blue: 0.20, alpha: 1)])!.draw(in: disc, angle: -90)
    guard let art = NSImage(contentsOf: dir.appendingPathComponent("twemoji/\(id).svg")) else { fatalError("twemoji/\(id).svg manquant (\(emoji))") }
    let side: CGFloat = 230
    art.draw(in: NSRect(x: (s - side) / 2, y: (s - side) / 2, width: side, height: side))
    NSGraphicsContext.restoreGraphicsState()
    let rep = NSBitmapImageRep(cgImage: cg.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: dir.appendingPathComponent("\(id).png"))
}
print(list.count, "images")
