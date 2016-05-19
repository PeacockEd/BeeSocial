//
//  AppConstants.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/15/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation
import UIKit

let KEY_UID = "uid"
let SHADOW_COLOR: CGFloat = 157.0 / 255.0

// Firebase Login Error Conditions
let LOGIN_USER_NOT_FOUND = -8
let LOGIN_INVALID_EMAIL = -5
let LOGIN_INVALID_PASSWORD = -6
let LOGIN_GENERIC_ERROR = -254
let LOGIN_CREATE_USER_ERROR = -9254

// Data Types
typealias AuthResponse = AuthResult<Bool, Int>

// Segues
let SEGUE_LOGGED_IN = "segueLoggedIn"
