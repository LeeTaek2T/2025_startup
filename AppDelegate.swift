
import UIKit
import RoomPlan

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 앱 실행 시 필요한 초기 설정 가능
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        // RoomPlan 지원 여부에 따라 Scene 설정 다르게 적용
        let configurationName: String = RoomCaptureSession.isSupported
            ? "Default Configuration"
            : "Unsupported Device"

        return UISceneConfiguration(name: configurationName, sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
