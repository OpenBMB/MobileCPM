/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import llama

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    /// llama.cpp main executor
    public var llamaState: LlamaState?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        Task {
            llamaState = await LlamaState()
            DispatchQueue.main.async {
                MBNet.shared.post(with: nil) { _ in
                }
            }
        }

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = .white
        self.window?.rootViewController = MBMainTabBarController()
        self.window?.makeKeyAndVisible()

        return true
    }
    
}
