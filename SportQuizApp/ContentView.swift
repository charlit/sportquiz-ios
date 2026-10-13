import SwiftUI
import WebKit
import GameKit
import StoreKit

// Le quiz est embarqué dans l'app (Game/index.html + questions.js) ; le classement passe par
// Game Center, un classement par mode. Ces classements doivent exister dans App Store Connect
// avec les identifiants sportquiz.<mode>, au format « Entier ».
let quizModes: Set<String> = ["foot", "multi", "hard", "hardfoot", "hardrugby", "hardbasket", "hardtennis", "hardf1", "hardvelo",
                               "hardfr", "hardes", "harduk", "hardde", "hardit", "hardwc", "hardcan",
                               "semaine"]   // défi de la semaine : classement Game Center récurrent, remis à zéro chaque lundi
func leaderboardID(_ mode: String) -> String { "sportquiz.\(mode)" }
// Badges → succès Game Center : désactivé pour la 1re version (les succès ne sont pas encore créés dans App Store Connect).
// Le quiz renvoie tous ses badges à chaque connexion : ceux gagnés d'ici là seront reportés dès que ce sera activé.
let reportsAchievements = false

// Version affichée en bas du profil, ex. « 1.0 (3) » (version App Store et numéro de build)
private let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))"

private let quizBackground = UIColor(red: 0x0a / 255, green: 0x12 / 255, blue: 0x20 / 255, alpha: 1)

// Diagnostic (variable d'environnement QUIZ_DIAGNOSTIC, ex. DEVICECTL_CHILD_QUIZ_DIAGNOSTIC=1 xcrun devicectl
// device process launch --console …) : la page envoie ses erreurs, les appuis et l'état de la partie,
// imprimés sur la sortie standard.
private let diagnosticScript = """
(() => {
  const send = m => webkit.messageHandlers.diag.postMessage(String(m));
  const who = el => el ? el.tagName + (el.id ? '#' + el.id : '') + (el.className ? '.' + el.className : '') + ' «' + (el.textContent || '').trim().slice(0, 24) + '»' : 'rien';
  addEventListener('error', e => send('ERREUR ' + e.message + ' @' + e.lineno));
  addEventListener('unhandledrejection', e => send('REJET ' + e.reason));
  for (const t of ['touchstart', 'touchend', 'touchcancel', 'click'])
    document.addEventListener(t, e => send(t + ' sur ' + who(e.target)), true);
  addEventListener('load', () => {
    for (const f of ['ask', 'answer', 'finish', 'start']) {
      const orig = window[f];
      window[f] = function () { send(f + ' idx=' + (typeof idx === 'number' ? idx : '?') + ' vies=' + lives); return orig.apply(this, arguments); };
    }
    setInterval(() => {
      const b = document.querySelector('#answers button');
      let cover = '';
      if (b) { const r = b.getBoundingClientRect(); cover = ' 1re réponse à y=' + Math.round(r.top) + ', au-dessus : ' + who(document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2)); }
      const visible = ['home', 'quiz', 'end'].find(s => !document.getElementById(s).classList.contains('hidden'));
      send('état écran=' + visible + ' idx=' + idx + ' boutons désactivés=' + document.querySelectorAll('#answers button:disabled').length +
           ' zoom=' + (visualViewport ? visualViewport.scale.toFixed(2) : '?') + ' scrollY=' + Math.round(scrollY) + cover);
    }, 3000);
  });
})();
"""

struct ContentView: View {
    var body: some View {
        QuizWebView(url: URL(string: "sportquiz://app/")!)
            .background(Color(quizBackground).ignoresSafeArea())
    }
}

struct QuizWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(context.coordinator.scheme, forURLScheme: "sportquiz")
        config.userContentController.addUserScript(
            WKUserScript(source: "window.__quizGC = true; window.__appVersion = \"\(appVersion)\";", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        // Pas de zoom dans l'app (pincement ni double appui) : page à taille fixe, comme une app native
        config.userContentController.addUserScript(WKUserScript(source: """
            document.querySelector('meta[name=viewport]')?.setAttribute('content', 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no');
            document.head.insertAdjacentHTML('beforeend', '<style>html { touch-action: manipulation; }</style>');
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        if ProcessInfo.processInfo.environment["QUIZ_DIAGNOSTIC"] != nil {
            config.userContentController.add(context.coordinator, name: "diag")
            config.userContentController.addUserScript(
                WKUserScript(source: diagnosticScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        config.userContentController.add(context.coordinator, name: "app")   // vibrations, partage, Game Center, avis
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsLinkPreview = false   // pas d'aperçu de lien sur un appui long : comportement d'app, pas de page web
        context.coordinator.webView = webView
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = quizBackground
        webView.scrollView.backgroundColor = quizBackground
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.delegate = context.coordinator
        webView.load(URLRequest(url: url))
        GameCenter.shared.authenticate { [weak webView] name in
            let arg = name.flatMap { try? String(data: JSONEncoder().encode($0), encoding: .utf8) } ?? "null"
            webView?.evaluateJavaScript("window.__quizPlayer && __quizPlayer(\(arg))")
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    // Sans ce délégué, confirm() (« Abandonner la partie ? ») répond toujours non dans une WKWebView.
    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, GKGameCenterControllerDelegate, UIScrollViewDelegate {
        let scheme = QuizSchemeHandler()
        weak var webView: WKWebView?
        private var loaded = false
        private var shortcutObserver: NSObjectProtocol?

        override init() {
            super.init()
            shortcutObserver = NotificationCenter.default.addObserver(forName: Shortcuts.received, object: nil, queue: .main) { [weak self] _ in
                self?.runPendingShortcut()
            }
        }

        // Raccourci de l'icône : exécuté dès que la page est prête (au lancement, elle ne l'est pas encore).
        private func runPendingShortcut() {
            guard loaded, let action = Shortcuts.pending else { return }
            Shortcuts.pending = nil
            webView?.evaluateJavaScript("window.__quizShortcut && __quizShortcut('\(action)')")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loaded = true
            runPendingShortcut()
        }

        // Les liens hors du quiz (mailto: du bouton de contact, http…) s'ouvrent dans l'app iOS adaptée :
        // la WKWebView ne sait pas les charger elle-même et le clic resterait sans effet.
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url, let scheme = url.scheme, scheme != "sportquiz", scheme != "about" else {
                return decisionHandler(.allow)
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "app", let body = message.body as? [String: Any], let type = body["type"] as? String else {
                return print("[quiz]", message.body)
            }
            switch type {
            case "haptic":   // bonne réponse, erreur, badge
                switch body["kind"] as? String {
                case "success": UINotificationFeedbackGenerator().notificationOccurred(.success)
                case "warning": UINotificationFeedbackGenerator().notificationOccurred(.warning)
                case "error": UINotificationFeedbackGenerator().notificationOccurred(.error)
                default: UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            case "share":    // feuille de partage iOS (Messages, WhatsApp, Instagram…)
                var items: [Any] = [body["text"] as? String ?? ""]
                if let url = (body["url"] as? String).flatMap(URL.init(string:)) { items.append(url) }
                let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let webView { sheet.popoverPresentationController?.sourceView = webView }
                if let webView { present(sheet, from: webView, orElse: {}) }
            case "gameCenter":   // écran Game Center natif, ouvert sur le classement affiché
                guard GKLocalPlayer.local.isAuthenticated, let webView else { return }
                let mode = body["mode"] as? String ?? "foot"
                let gc = quizModes.contains(mode)
                    ? GKGameCenterViewController(leaderboardID: leaderboardID(mode), playerScope: .global, timeScope: .allTime)
                    : GKGameCenterViewController(state: .leaderboards)
                gc.gameCenterDelegate = self
                present(gc, from: webView, orElse: {})
            case "review":   // demande d'avis App Store (iOS limite son affichage à 3 fois par an)
                if let scene = webView?.window?.windowScene { SKStoreReviewController.requestReview(in: scene) }
            default:
                print("[quiz] message inconnu", type)
            }
        }

        // Refuse tout zoom de la page (le pincement est déjà coupé, ceci couvre les autres cas)
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { nil }

        func gameCenterViewControllerDidFinish(_ controller: GKGameCenterViewController) {
            controller.dismiss(animated: true)
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Annuler", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in completionHandler(true) })
            present(alert, from: webView, orElse: { completionHandler(false) })
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            present(alert, from: webView, orElse: completionHandler)
        }

        // Présente l'alerte au-dessus de ce qui est déjà affiché (ex. une feuille Game Center).
        // Si c'est impossible, on répond tout de suite : sinon la page reste figée à attendre la réponse.
        private func present(_ alert: UIViewController, from view: UIView, orElse fallback: @escaping () -> Void) {
            var top = view.window?.rootViewController
            while let next = top?.presentedViewController, !next.isBeingDismissed { top = next }
            guard let top, top.viewIfLoaded?.window != nil, !top.isBeingDismissed else {
                print("[quiz] alerte impossible à afficher : réponse par défaut")
                return fallback()
            }
            top.present(alert, animated: true)
        }
    }
}

final class GameCenter {
    static let shared = GameCenter()
    var playerName: String? { GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local.displayName : nil }

    func authenticate(onChange: @escaping (String?) -> Void) {
        GKLocalPlayer.local.authenticateHandler = { vc, error in
            print("[quiz] Game Center :", vc != nil ? "écran de connexion" : "pas d'écran",
                  GKLocalPlayer.local.isAuthenticated ? "connecté" : "non connecté", error.map { "\($0)" } ?? "")
            if let vc {
                let root = UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
                root?.present(vc, animated: true)
            }
            onChange(self.playerName)
        }
    }

    // Le « context » du score Game Center porte le nombre de bonnes réponses et celui des badges : badges × 1000 + bonnes.
    // Game Center ne garde que le meilleur score : le nombre de badges affiché est celui du jour de ce record.
    func submit(mode: String, score: Int, good: Int, badges: Int) async throws {
        try await GKLeaderboard.submitScore(score, context: badges * 1000 + good % 1000, player: GKLocalPlayer.local,
                                            leaderboardIDs: [leaderboardID(mode)])
    }

    // Badges du quiz = succès Game Center « sportquiz.badge.<id> » (à créer dans App Store Connect).
    // Le quiz renvoie tous ses badges à chaque connexion : un succès déjà gagné ne réaffiche pas de bannière.
    func unlock(badges ids: [String]) async throws {
        let done = Set(try await GKAchievement.loadAchievements().filter(\.isCompleted).map(\.identifier))
        let todo = ids.map { "sportquiz.badge.\($0)" }.filter { !done.contains($0) }.map { id -> GKAchievement in
            let a = GKAchievement(identifier: id)
            a.percentComplete = 100
            a.showsCompletionBanner = false   // le quiz affiche déjà son propre bandeau « Badge débloqué »
            return a
        }
        if !todo.isEmpty { try await GKAchievement.report(todo) }
    }

    func top(mode: String, _ n: Int = 20) async throws -> [[String: Any]] {
        guard let board = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID(mode)]).first else { return [] }
        let (_, entries, _) = try await board.loadEntries(for: .global, timeScope: .allTime,
                                                          range: NSRange(location: 1, length: n))
        return entries.map { ["name": $0.player.displayName, "score": $0.score, "good": $0.context % 1000, "badges": $0.context / 1000] }
    }
}

// Sert sportquiz://app/ depuis le bundle, et répond à sportquiz://app/api/... avec Game Center
// (même format que server.py, pour que le quiz n'ait presque rien à changer).
final class QuizSchemeHandler: NSObject, WKURLSchemeHandler {
    private static let files = ["index.html": "text/html; charset=utf-8",
                                "questions.js": "text/javascript; charset=utf-8",
                                "clubs.js": "text/javascript; charset=utf-8",
                                "semaine.js": "text/javascript; charset=utf-8",
                                "matchs.js": "text/javascript; charset=utf-8",
                                "derbies.js": "text/javascript; charset=utf-8"]
    private var active = Set<ObjectIdentifier>()   // tâches non annulées (accès sur le main thread)

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        active.insert(ObjectIdentifier(task))
        if url.path.hasPrefix("/api/") {
            let request = task.request
            Task { @MainActor in
                do {
                    let body = try await self.api(url, request)
                    self.finish(task, url, 200, "application/json", try JSONSerialization.data(withJSONObject: body))
                } catch {
                    self.finish(task, url, 503, "application/json", Data("{}".utf8))
                }
            }
            return
        }
        let name = url.path == "/" ? "index.html" : url.lastPathComponent
        if let type = Self.files[name],
           let file = Bundle.main.url(forResource: name, withExtension: nil),
           let data = try? Data(contentsOf: file) {
            finish(task, url, 200, type, data)
        } else {
            finish(task, url, 404, "text/plain", Data())
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {
        active.remove(ObjectIdentifier(task))
    }

    private func api(_ url: URL, _ request: URLRequest) async throws -> Any {
        let gc = GameCenter.shared
        switch (url.path, request.httpMethod ?? "GET") {
        case ("/api/me", _):
            return gc.playerName.map { ["name": $0] } ?? [:]
        case ("/api/achievements", "POST") where !reportsAchievements:
            return [:]
        case ("/api/achievements", "POST"):
            guard let json = try JSONSerialization.jsonObject(with: Self.body(request)) as? [String: Any],
                  let ids = json["ids"] as? [String], gc.playerName != nil else { throw URLError(.userAuthenticationRequired) }
            try await gc.unlock(badges: ids)
            return [:]
        case ("/api/scores", "POST"):
            guard let json = try JSONSerialization.jsonObject(with: Self.body(request)) as? [String: Any],
                  let mode = json["mode"] as? String, quizModes.contains(mode),
                  let score = json["score"] as? Int, let good = json["good"] as? Int,
                  let name = gc.playerName else { throw URLError(.badURL) }
            let badges = max(0, json["badges"] as? Int ?? 0)
            try await gc.submit(mode: mode, score: score, good: good, badges: badges)
            // Game Center met parfois quelques secondes à refléter un nouveau score : on l'ajoute nous-mêmes.
            var rows = try await gc.top(mode: mode)
            let mine = rows.firstIndex { ($0["name"] as? String) == name }
            if mine == nil || (rows[mine!]["score"] as? Int ?? 0) < score {
                if let mine { rows.remove(at: mine) }
                rows.append(["name": name, "score": score, "good": good, "badges": badges])
                rows.sort { ($0["score"] as? Int ?? 0) > ($1["score"] as? Int ?? 0) }
                rows = Array(rows.prefix(20))
            } else if let mine {
                rows[mine]["badges"] = badges   // au moins sur cet écran, le joueur voit son nombre de badges à jour
            }
            return rows
        case ("/api/scores", _):
            let mode = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "mode" }?.value ?? ""
            guard quizModes.contains(mode) else { throw URLError(.badURL) }
            return try await gc.top(mode: mode)
        default:
            throw URLError(.fileDoesNotExist)
        }
    }

    // WebKit fournit le corps d'un POST soit en Data, soit en flux.
    private static func body(_ request: URLRequest) -> Data {
        if let data = request.httpBody { return data }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open(); defer { stream.close() }
        var data = Data(), buf = [UInt8](repeating: 0, count: 4096)
        while case let n = stream.read(&buf, maxLength: buf.count), n > 0 { data.append(buf, count: n) }
        return data
    }

    private func finish(_ task: WKURLSchemeTask, _ url: URL, _ code: Int, _ type: String, _ data: Data) {
        guard active.remove(ObjectIdentifier(task)) != nil else { return }
        task.didReceive(HTTPURLResponse(url: url, statusCode: code, httpVersion: "HTTP/1.1",
                                        headerFields: ["Content-Type": type])!)
        task.didReceive(data)
        task.didFinish()
    }
}
