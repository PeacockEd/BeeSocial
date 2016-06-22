//
//  ViewController.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/14/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!
    
    private var attemptedPwd:String?
    private var attemptedEmail:String?
    
    private var newUser = false
    private var loginManager: LoginManager!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        emailTxtField.autocorrectionType = .No
        emailTxtField.autocapitalizationType = .None
        
        loginManager = LoginManager()
        loginManager.delegate = self
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if loginManager.userExists() {
            performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SEGUE_LOGGED_IN {
            if let nvc = segue.destinationViewController as? UINavigationController,
                dvc = nvc.topViewController as? PostsVC
            {
                dvc.loginManager = loginManager
                dvc.newUser = newUser
            }
        }
    }
    
    func showLoginErrorPrompt(withTitle title: String, withMsg msg: String)
    {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(alertAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func showCreateUserPrompt(withTitle title:String, withMsg msg:String)
    {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let alertOkAction = UIAlertAction(title: "OK", style: .Default, handler: onDismissCreateUserPrompt)
        let alertCancelAction = UIAlertAction(title: "Cancel", style: .Default, handler:onDismissCreateUserPrompt)
        alert.addAction(alertOkAction)
        alert.addAction(alertCancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func onDismissCreateUserPrompt(action:UIAlertAction)
    {
        if let btnAction = action.title where btnAction == "OK" {
            if let email = attemptedEmail, let pwd = attemptedPwd {
                loginManager.createNewUser(email, password: pwd)
            } else {
                showLoginErrorPrompt(withTitle: "Login Error", withMsg: "Unable to create user. Please try again.")
            }
        } else {
            clearLoginForm()
        }
    }
    
    func clearLoginForm()
    {
        emailTxtField.text = ""
        passwordTxtField.text = ""
    }
    
    @IBAction func onLoginBtnTapped(sender: UIButton!)
    {
        if let email = emailTxtField.text where email != "",
            let pwd = passwordTxtField.text where pwd != "" {
            
            self.attemptedEmail = email
            self.attemptedPwd = pwd
            
            loginManager.authenticateUser(email, password: pwd)
            
        } else {
            showLoginErrorPrompt(withTitle: "Login Error", withMsg: "You must enter a valid username and password.")
        }
    }
    
    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {}
}

extension ViewController: LoginManagerDelegate
{
    func onAuthenticationResult(result: AuthResponse) {
        if result.error == nil {
            performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
            clearLoginForm()
        } else {
            if let error = result.error {
                switch(error) {
                case LOGIN_USER_NOT_FOUND:
                    showCreateUserPrompt(withTitle: "Login Error", withMsg: "This username does not exist. Do you wish to create a new account with this username/password?")
                case LOGIN_INVALID_PASSWORD:
                    showLoginErrorPrompt(withTitle: "Login Error", withMsg: "Your password is incorrect. Please login again.")
                default:
                    self.showLoginErrorPrompt(withTitle: "Login Error", withMsg: "A problem occured while attempting to Login.")
                }
            }
        }
    }
    
    func onCreateUserResult(result: AuthResponse)
    {
        if result.error != nil {
            showLoginErrorPrompt(withTitle: "Login Error", withMsg: "A problem occured while attempting to create this account.")
        } else {
            newUser = true
            performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    }   
}