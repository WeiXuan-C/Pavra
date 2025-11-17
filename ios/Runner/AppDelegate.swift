import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with API key from .env file
    var apiKey = "AIzaSyA6TR3OKPNvhuFpRXvObP9t0O_Qthgqo2Y" // Fallback key
    
    // Try to load from .env file
    if let path = Bundle.main.path(forResource: ".env", ofType: nil),
       let contents = try? String(contentsOfFile: path, encoding: .utf8) {
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("GOOGLE_MAPS_API_KEY=") {
                apiKey = line.replacingOccurrences(of: "GOOGLE_MAPS_API_KEY=", with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }
    }
    
    GMSServices.provideAPIKey(apiKey)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
