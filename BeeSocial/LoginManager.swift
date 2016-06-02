//
//  LoginManager.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/17/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation
import Firebase

protocol LoginManagerDelegate: class {
    func onAuthenticationResult(result:AuthResponse)
    func onCreateUserResult(result:AuthResponse)
}

class LoginManager: NSObject {
    
    weak var delegate:LoginManagerDelegate?
    
    
    func authenticateUser(email: String, password pwd:String)
    {
        FIRAuth.auth()?.signInWithEmail(email, password: pwd) { user, error in
            var result:AuthResponse = AuthResponse.Failure(LOGIN_GENERIC_ERROR)
            if error != nil {
                print(error.debugDescription)
                switch(error!.code) {
                case LOGIN_USER_NOT_FOUND:
                    result = AuthResponse.Failure(LOGIN_USER_NOT_FOUND)
                case LOGIN_INVALID_PASSWORD:
                    result = AuthResponse.Failure(LOGIN_INVALID_PASSWORD)
                default:
                    result = AuthResponse.Failure(LOGIN_GENERIC_ERROR)
                }
            } else {
                if let user = user {
                    print("*** USER ALREADY EXISTED AND USER LOGGED IN: \(user.uid)")
                    result = AuthResponse.Success(true)
                }
            }
            self.delegate?.onAuthenticationResult(result)
        }
    }
    
    func createNewUser(email:String, password pwd:String)
    {
        FIRAuth.auth()?.createUserWithEmail(email, password: pwd) { user, error in
            if error != nil {
                self.delegate?.onCreateUserResult(AuthResponse.Failure(LOGIN_CREATE_USER_ERROR))
            } else {
                if let user = user {
                    print("*** USER CREATED AND LOGGED IN: \(user.uid)")
                    self.delegate?.onCreateUserResult(AuthResponse.Success(true))
                }
            }
        }
    }
    
    func userExists() -> Bool
    {
        if let _ = FIRAuth.auth()?.currentUser {
            return true
        }
        return false
    }
}