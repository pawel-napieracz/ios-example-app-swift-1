//
// Copyright (c) 2018 Onegini. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var navigationController = AppAssembly.shared.resolver.resolve(UINavigationController.self)
    var appRouter = AppAssembly.shared.resolver.resolve(AppRouterProtocol.self)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setupWindow()
        registerForPushMessages(application: application)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        oneginiSDKStartup()

        return true
    }

    func setupWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        window?.makeKeyAndVisible()
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "background"), for: .default)
        window?.rootViewController = navigationController
    }

    func oneginiSDKStartup() {
        guard let appRouter = appRouter else { fatalError() }
        appRouter.setupStartupPresenter()
    }

    func registerForPushMessages(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { permissionGranted, error in
            if let error = error {
                
            }
        }
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MobileAuthEntrollmentEntity.shared.deviceToken = deviceToken
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
}

