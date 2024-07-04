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

import Foundation
import Alamofire

/// net requester
class MBNet: NSObject {
    
    // singleton
    static let shared = MBNet()
    
    private override init() {}
    
    override func copy() -> Any {
        // SingletonClass.shared
        return self
    }
    
    override func mutableCopy() -> Any {
        // SingletonClass.shared
        return self
    }

    typealias MBURLCompletion = (Result<NSDictionary, Error>) -> Void

}

extension MBNet {
    
    public func post(with path: String?, completion: @escaping MBURLCompletion) {
        AF.request("https://log-server.ali.modelbest.cn/sa.gif?project=mobilecpm",
                   method: .post,
                   parameters: ["crc": -1560065520, "gzip": 1, "data_list": "H4sIAAAAAAAAE+1Y0W7aMBT9F6+PBDmJkzi8kVK0Pkyb1Gl7mKbIJQ5YJXbkODBW9U+mvewnpn7Qpv3FbkIoqIWWVp1GETyAbO71vT73nmPLny4Rk0rOMlUWsUhQB4VRNzyOnL7l9iLXItgnVoSj0HI9L4QRdXtdjFooNpoNLmoXgl0cENchuIX4hEsDq7xWGc/ZkMdnIzUFcyMyjjp24GDsY+J5thO2kEjAWBjBC9S5REfNcBY/LaOlv0jSCfhhHEQ4dCKrS21qkX63b3W7PccK3BMS0Mg/gazRVQuNxXkdH37jCdeFUBK8STto18vWfyPx9qwasDxfsbHBxm5s4oybkaryHaiEV+vmWuVc32xPFctlioHmXMZTkZgR6rihC1moYWxmOaCEHNQAuZh4B0g2QM7nJavgvIPypvREEadCFyZO2Ax1UjYuOMxmkOcYzL5QP/ZJZZfwiRjwOepboQc+kpup0heLVD+e9k9hGiJKPl3Gqur/VUkeqzQtOHSIRShuEm428/v6558f3399uwb3qUgFTNU/YDUfGl3yemWASsjFuKyztQmmto2d0PVslziYrqA84mI4gpDUc9aWqrWx9KpYRTNoe3f6IWOyTNnAlJprmO3m+bhasC7mrZZvQ887oddsWszDZ+26Cue8MO2cQbvkYybr7klEYYQcmEdxoClCzc2KpOm4LEa3MgmoR7yr1jMQ38auR4H8mCyJfwQQnBmmzRrSE+rvLelZadT7Gvb7mb9hrTWCsMOs1bwoMx6nWmXxOex5qFUpk6Xff2b1shaPpPYN4vPOXWxnG8bvDalDYocB8asOXOX0B8GnZzXya4jtUWcniZ1ww0RFljdRdVRWezhW0mg1HnP9qv7c0yIHDfi3J/dRqTfVBj2nAjTmTbIbwj37FWBvBMGmgev4gXf7lH9AEchuK0JPacYzJeGuYsoiYvogDrsoDg+U6Qk6oXnK9Zyq90nBNlLycHIHVdmoKn4QYlCWINz20SCgjk93UlQOjwYvTV1eyKNBQNvQ877j7hHxXbhJ2D6G720eDSCue3g02Is7weHRYDdP889/AQcO0TsEGAAA", "event": "app_start"],
                   headers: [
                    .init(name: "x-device", value: "iOS"),
                    .init(name: "x-version", value: "1.0.0"),
                    .accept("application/json")
                ]).response { response in
            completion(.success(["response": response]))
        }
    }
}
