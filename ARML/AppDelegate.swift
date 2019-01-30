//
//  AppDelegate.swift
//  ARML
//
//  Created by Gil Nakache on 24/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        let viewController = ARViewController()

        window?.rootViewController = viewController

        window?.makeKeyAndVisible()

        return true
    }
}
