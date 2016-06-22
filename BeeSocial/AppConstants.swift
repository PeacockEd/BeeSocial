//
//  AppConstants.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/15/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation
import UIKit
import Firebase

let BASE_REF = FIRDatabase.database().reference()
let BASE_STORAGE_REF = FIRStorage.storage().referenceForURL("gs://project-1910258691540389069.appspot.com")

// FireBase Key Names
struct MessageFields {
    static let posts = "posts"
    static let users = "users"
    static let description = "description"
    static let imageUrl = "imageUrl"
    static let likes = "likes"
    static let username = "username"
    static let authMethod = "auth-method"
}

// FireBase Notifications
struct NotificationKeys {
    static let signedOut = "signedOut"
}

// UI Helpers
let SHADOW_COLOR: CGFloat = 157.0 / 255.0

// Firebase Login Error Conditions
let LOGIN_USER_NOT_FOUND = 17011
let LOGIN_INVALID_EMAIL = -5
let LOGIN_INVALID_PASSWORD = 17009
let LOGIN_GENERIC_ERROR = -254
let LOGIN_CREATE_USER_ERROR = -9254

// Firebase Data Error Conditions
let DATA_UNEXPECTED_FORMAT_ERROR = "dataUnexpectedFormatError"

// Data Types
typealias AuthResponse = AuthResult<Bool, Int>

// Segues
let SEGUE_LOGGED_IN = "segueLoggedIn"
let SEGUE_PROFILE_INFO = "segueProfileInfo"
