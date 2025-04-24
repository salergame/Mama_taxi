import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAPbtO3t20UTgn_9L87YLHiBnOoMtZJ3YY")
    // Устанавливаем русский язык для карт Google
    GMSServices.setLenient(true)
    if let languageID = Locale.preferredLanguages.first {
      GMSServices.setPreferredLanguage("ru")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
