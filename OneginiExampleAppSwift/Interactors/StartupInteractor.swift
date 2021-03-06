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

protocol StartupInteractorProtocol {
    func oneginiSDKStartup(completion: @escaping (Bool, AppError?) -> Void)
}

class StartupInteractor: StartupInteractorProtocol {
    func oneginiSDKStartup(completion: @escaping (Bool, AppError?) -> Void) {
        ONGClientBuilder().build()
        ONGClient.sharedInstance().start { result, error in
            if let error = error {
                let mappedError = ErrorMapper().mapError(error)
                completion(result, mappedError)
            } else {
                completion(result, nil)
            }
        }
    }
}
