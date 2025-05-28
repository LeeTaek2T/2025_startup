//
//  AppDelegate.swift
//  University_Project
//
//  Created by 이택 on 5/19/25.
//

import UIKit
import RoomPlan

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 앱 실행 시 필요한 초기 설정 가능
        return true
    }

    // MARK: UISceneSession Lifecycle
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
        // 사용자가 세션을 종료했을 때 처리할 작업 (일반적으로 비워둬도 무방)
    }
}
