import SwiftUI
import UIKit

@main
struct SportQuizApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Raccourcis de l'icône (appui long sur l'écran d'accueil) : Spécial Foot, Hardcore, Aventure, Classement.
// Définis dans Info.plist (UIApplicationShortcutItems) ; l'action est transmise à la page par QuizWebView.
enum Shortcuts {
    static let received = Notification.Name("QuizShortcut")
    static var pending: String?

    static func handle(_ item: UIApplicationShortcutItem) {
        pending = item.type.components(separatedBy: ".").last
        NotificationCenter.default.post(name: received, object: nil)
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let item = options.shortcutItem { Shortcuts.handle(item) }   // app lancée par un raccourci
        let config = UISceneConfiguration(name: nil, sessionRole: session.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    // app déjà ouverte en arrière-plan
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        Shortcuts.handle(shortcutItem)
        completionHandler(true)
    }
}
