import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "crowleys_cloud_background_sync",
      earliestBeginInSeconds: NSNumber(value: 15 * 60)
    )
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "dev.fluttercommunity.workmanager.BackgroundProcessingTask")
    WorkmanagerPlugin.registerLaunchHandlers()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
