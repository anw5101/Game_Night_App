import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct GameNightApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var locationManager = LocationManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var authManager = AuthManager()
    @StateObject private var eventScraper = EventScraper()

    var body: some Scene {
        WindowGroup {
            ContentView(
                locationManager: locationManager,
                favoritesManager: favoritesManager,
                authManager: authManager,
                eventScraper: eventScraper
            )
            .environmentObject(locationManager)
            .environmentObject(favoritesManager)
            .environmentObject(authManager)
            .environmentObject(eventScraper)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
