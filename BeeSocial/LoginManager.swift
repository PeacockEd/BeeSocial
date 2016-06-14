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
    
    override init()
    {
        super.init()
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if user == nil {
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.signedOut, object: nil)
            }
        }
    }
    
    func authenticateUser(email: String, password pwd:String)
    {
        FIRAuth.auth()?.signInWithEmail(email, password: pwd) { user, error in
            var result:AuthResponse?
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
                if let result = result {
                    self.delegate?.onAuthenticationResult(result)
                }
            } else {
                if let user = user {
                    print("*** USER ALREADY EXISTED AND USER LOGGED IN: \(user.uid)")
                    result = AuthResponse.Success(true)
                    self.signedIn(user) {
                        self.delegate?.onAuthenticationResult(result!)
                    }
                }
            }
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
                    var userData = [MessageFields.username : email]
                    userData[MessageFields.authMethod] = "email"
                    BASE_REF.child(MessageFields.users).child(user.uid).setValue(userData, withCompletionBlock: { (error, dbRef) in
                        self.setDisplayName(user) {
                            self.delegate?.onCreateUserResult(AuthResponse.Success(true))
                        }
                    })
                }
            }
        }
    }
    
    private func setDisplayName(user: FIRUser, completionHandler handler: () -> ())
    {
        let changeRequest = user.profileChangeRequest()
        changeRequest.displayName = user.email?.componentsSeparatedByString("@")[0] ?? "New User"
        changeRequest.commitChangesWithCompletion { error in
            guard error == nil else {
                return
            }
            self.signedIn(user, completionHandler: handler)
        }
    }
    
    private func signedIn(user: FIRUser, completionHandler handler: (() -> ())?)
    {
        AppState.sharedInstance.displayName = user.displayName ?? user.email
        if handler != nil {
            handler!()
        }
    }
    
    func logout()
    {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error as NSError {
            print(error)
        }
    }
    
    func userExists() -> Bool
    {
        if let user = FIRAuth.auth()?.currentUser {
            signedIn(user, completionHandler: nil)
            return true
        }
        return false
    }
}