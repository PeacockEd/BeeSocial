//
//  LoginManager.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/17/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation

protocol LoginManagerDelegate: class {
    func onAuthenticationResult(result:AuthResponse)
    func onCreateUserResult(result:AuthResponse)
}

class LoginManager: NSObject {
    
    weak var delegate:LoginManagerDelegate?
    
    
    func authenticateUser(email: String, password pwd:String)
    {
        DataProxy.instance.BASE_FB_REF.authUser(email, password: pwd) { error, authData in
            
            var result:AuthResponse
            if error != nil {
                switch(error.code) {
                case LOGIN_USER_NOT_FOUND:
                    result = AuthResponse.Failure(LOGIN_USER_NOT_FOUND)
                case LOGIN_INVALID_PASSWORD:
                    result = AuthResponse.Failure(LOGIN_INVALID_PASSWORD)
                default:
                    result = AuthResponse.Failure(LOGIN_GENERIC_ERROR)
                }
            } else {
                print("*** USER ALREADY EXISTED AND USER LOGGED IN: \(authData)")
                NSUserDefaults.standardUserDefaults().setValue("\(authData)", forKey: KEY_UID)
                result = AuthResponse.Success(true)
                
            }
            self.delegate?.onAuthenticationResult(result)
        }
    }
    
    func createNewUser(email:String, password pwd:String)
    {
        DataProxy.instance.BASE_FB_REF.createUser(email, password: pwd) {
            error, result in
            if error != nil {
                self.delegate?.onCreateUserResult(AuthResponse.Failure(LOGIN_CREATE_USER_ERROR))
            } else {
                NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID], forKey: KEY_UID)
                DataProxy.instance.BASE_FB_REF.authUser(email, password: pwd) {
                    error, authData in
                    print("*** USER CREATED AND LOGGED IN: \(authData)")
                    self.delegate?.onCreateUserResult(AuthResponse.Success(true))
                }
            }
        }
    }
    
    func isCachedUser() -> Bool
    {
        if let _ = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) {
            return true
        }
        return false
    }
}