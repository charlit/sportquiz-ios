// Captures App Store : voir AppStore/fiche.md.
import AppKit
import WebKit

// Captures App Store 6,9" (440 × 956 points × 3 = 1320 × 2868) de la page du quiz, rendue par WebKit.
let game = URL(fileURLWithPath: CommandLine.arguments[1])          // dossier Game (index.html, questions.js, clubs.js)
let out = URL(fileURLWithPath: CommandLine.arguments[2])
let states = try! JSONSerialization.jsonObject(with: Data(contentsOf: out.appendingPathComponent("states.json"))) as! [String: Any]
func js(_ v: Any) -> String { String(data: try! JSONSerialization.data(withJSONObject: v), encoding: .utf8)! }

let rows = js([["name": "Pilou", "score": 24870, "good": 91, "badges": 14], ["name": "Mila_10", "score": 23410, "good": 88, "badges": 11], ["name": "Toi", "score": 21950, "good": 85, "badges": 9], ["name": "Sacha.B", "score": 19300, "good": 80, "badges": 8], ["name": "Nono14", "score": 17820, "good": 77, "badges": 6], ["name": "Lucas", "score": 16100, "good": 72, "badges": 7], ["name": "Inès", "score": 14250, "good": 68, "badges": 4], ["name": "Gaby", "score": 12980, "good": 64, "badges": 5], ["name": "Rémi", "score": 11400, "good": 60, "badges": 3], ["name": "Lulu", "score": 9870, "good": 55, "badges": 2]])
let badges = js(states["badges"]!)
// nom, localStorage avant chargement, action après chargement
let shots: [(String, [String: String], String)] = [
    ("1-accueil", ["quiz-badges": badges], ""),
    ("2-question", ["quiz-badges": badges], "start('foot'); idx = 41; score = 8340; good = 39; lives = 2; $('score').textContent = score; ask();"),
    ("3-aventure-carte", ["quiz-adv": js(states["partial"]!), "quiz-badges": badges], "advLand = 'fr'; cityFilter = null; openClubs();"),
    ("4-aventure-pays", ["quiz-adv": js(states["frdone"]!), "quiz-adv-open": js(["fr", "es"]), "quiz-badges": badges], "openLands();"),
    ("5-classement", ["quiz-badges": badges], "show('ranks'); renderBoard(\(rows), $('board'), 'Toi', 'foot');"),
    ("6-badges", ["quiz-badges": badges], "window.__quizPlayer && __quizPlayer('Toi'); $('goBadges').click();"),
]

final class Shooter: NSObject, WKNavigationDelegate {
    var i = 0, web: WKWebView!
    let window = NSWindow(contentRect: NSRect(x: -5000, y: -5000, width: 440, height: 956), styleMask: [.borderless], backing: .buffered, defer: false)
    func next() {
        guard i < shots.count else { exit(0) }
        let (_, storage, _) = shots[i]
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let pre = "localStorage.clear();" + storage.map { "localStorage.setItem(\(js([$0.key]).dropFirst().dropLast()), \(js([$0.value]).dropFirst().dropLast()));" }.joined()
        config.userContentController.addUserScript(WKUserScript(source: "window.__quizGC = true;" + pre, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        web = WKWebView(frame: NSRect(x: 0, y: 0, width: 440, height: 956), configuration: config)
        web.navigationDelegate = self
        window.contentView = web           // WebKit ne dessine que dans une fenêtre
        window.orderFrontRegardless()
        web.loadFileURL(game.appendingPathComponent("index.html"), allowingReadAccessTo: game)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let (name, _, action) = shots[i]
        webView.evaluateJavaScript(action) { _, err in
            if let err { print(name, "ERREUR", err) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                let cfg = WKSnapshotConfiguration()
                cfg.snapshotWidth = NSNumber(value: 1320 / (NSScreen.main?.backingScaleFactor ?? 2))   // 1320 pixels de large
                webView.takeSnapshot(with: cfg) { img, err in
                    guard let img, let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print(name, "échec", err as Any); exit(1) }
                    // 1320 × 2868 pixels, opaque (l'App Store refuse la transparence)
                    let ctx = CGContext(data: nil, width: 1320, height: 2868, bitsPerComponent: 8, bytesPerRow: 0,
                                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
                    ctx.interpolationQuality = .high
                    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 1320, height: 2868))
                    let dest = CGImageDestinationCreateWithURL(out.appendingPathComponent("\(name).png") as CFURL, "public.png" as CFString, 1, nil)!
                    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil); CGImageDestinationFinalize(dest)
                    print(name, "ok")
                    self.i += 1; self.next()
                }
            }
        }
    }
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let s = Shooter()
DispatchQueue.main.async { s.next() }
app.run()
