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

protocol RegisterUserInteractorProtocol: AnyObject {
    func identityProviders() -> Array<ONGIdentityProvider>
    func startUserRegistration(identityProvider: ONGIdentityProvider?)
    func handleRedirectURL()
    func handleCreatedPin()
    func handleOTPCode()
}

class RegisterUserInteractor: NSObject {
    weak var registerUserPresenter: RegisterUserInteractorToPresenterProtocol?
    var registerUserEntity = RegisterUserEntity()

    fileprivate func mapErrorFromChallenge(_ challenge: ONGCreatePinChallenge) {
        if let error = challenge.error {
            registerUserEntity.pinError = ErrorMapper().mapError(error)
        } else {
            registerUserEntity.pinError = nil
        }
    }
}

extension RegisterUserInteractor: RegisterUserInteractorProtocol {
    func identityProviders() -> Array<ONGIdentityProvider> {
        let identityProviders = ONGUserClient.sharedInstance().identityProviders()
        return Array(identityProviders)
    }

    func startUserRegistration(identityProvider: ONGIdentityProvider? = nil) {
        ONGUserClient.sharedInstance().registerUser(with: identityProvider, scopes: ["read"], delegate: self)
    }

    func handleRedirectURL() {
        guard let browserRegistrationChallenge = registerUserEntity.browserRegistrationChallenge else { return }
        if let url = registerUserEntity.redirectURL {
            browserRegistrationChallenge.sender.respond(with: url, challenge: browserRegistrationChallenge)
        } else {
            browserRegistrationChallenge.sender.cancel(browserRegistrationChallenge)
        }
    }
    
    func handleOTPCode() {
        guard let customRegistrationChallenge = registerUserEntity.customRegistrationChallenge else { return }
        if registerUserEntity.cancelled {
            registerUserEntity.cancelled = false
            customRegistrationChallenge.sender.cancel(customRegistrationChallenge)
        } else {
            customRegistrationChallenge.sender.respond(withData: registerUserEntity.responseCode, challenge: customRegistrationChallenge)
        }
    }

    func handleCreatedPin() {
        guard let createPinChallenge = registerUserEntity.createPinChallenge else { return }
        if let pin = registerUserEntity.pin {
            createPinChallenge.sender.respond(withCreatedPin: pin, challenge: createPinChallenge)
        } else {
            createPinChallenge.sender.cancel(createPinChallenge)
        }
    }
    
    fileprivate func mapErrorMessageFromStatus(_ status: Int) {
        if status == 2000 {
            registerUserEntity.errorMessage = nil
        } else if status == 4002 {
            registerUserEntity.errorMessage = "This code is not initialized on portal."
        } else {
            registerUserEntity.errorMessage = "Provided code is incorrect."
        }
    }
}

extension RegisterUserInteractor: ONGRegistrationDelegate {
    func userClient(_: ONGUserClient, didReceive challenge: ONGBrowserRegistrationChallenge) {
        registerUserEntity.browserRegistrationChallenge = challenge
        registerUserEntity.registrationUserURL = challenge.url
        registerUserPresenter?.presentBrowserUserRegistrationView(regiserUserEntity: registerUserEntity)
    }

    func userClient(_: ONGUserClient, didReceivePinRegistrationChallenge challenge: ONGCreatePinChallenge) {
        registerUserEntity.createPinChallenge = challenge
        registerUserEntity.pinLength = Int(challenge.pinLength)
        mapErrorFromChallenge(challenge)
        registerUserPresenter?.presentCreatePinView(registerUserEntity: registerUserEntity)
    }

    func userClient(_: ONGUserClient, didRegisterUser userProfile: ONGUserProfile, info _: ONGCustomInfo?) {
        registerUserPresenter?.presentDashboardView(authenticatedUserProfile: userProfile)
    }

    func userClient(_: ONGUserClient, didFailToRegisterWithError error: Error) {
        if error.code == ONGGenericError.actionCancelled.rawValue {
            registerUserPresenter?.registerUserActionCancelled()
        } else {
            let mappedError = ErrorMapper().mapError(error)
            registerUserPresenter?.registerUserActionFailed(mappedError)
        }
    }

    func userClient(_: ONGUserClient, didReceiveCustomRegistrationInitChallenge challenge: ONGCustomRegistrationChallenge) {
        if challenge.identityProvider.identifier == "2-way-otp-api" {
            challenge.sender.respond(withData: nil, challenge: challenge)
        }
    }

    func userClient(_: ONGUserClient, didReceiveCustomRegistrationFinish challenge: ONGCustomRegistrationChallenge) {
        if challenge.identityProvider.identifier == "2-way-otp-api" {
            if let info = challenge.info {
                registerUserEntity.challengeCode = info.data
                mapErrorMessageFromStatus(info.status)
            }
            registerUserEntity.customRegistrationChallenge = challenge
            registerUserPresenter?.presentTwoWayOTPRegistrationView(regiserUserEntity: registerUserEntity)
        }
    }
}
