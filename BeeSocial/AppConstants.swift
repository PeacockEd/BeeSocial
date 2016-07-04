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
    static let postedbyUserId = "postedByUserId"
    static let authMethod = "auth-method"
    static let profileImgUrl = "profileImgUrl"
    static let timestamp = "timestamp"
}

// FireBase Notifications
struct NotificationKeys {
    static let signedOut = "signedOut"
}

// UI Helpers
let SHADOW_COLOR: CGFloat = 157.0 / 255.0

// Settings values
let PROFILE_THUMB_SIZE: CGSize = CGSizeMake(200.0, 200.0)
let POST_IMAGE_SIZE: CGSize = CGSizeMake(600.00, 600.0)
let PROFILE_IMAGE_FILE_SUFFIX = "-thumb.png"

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

// Error Prompt Strings
let PROMPT_IMAGE_ERROR_TITLE = "Error Saving Image"
let PROMPT_IMAGE_ERROR_MSG = "There was an unknown problem while attempting to send your image."
let PROMPT_POST_ERROR_TITLE = "Error Creating New Post"
let PROMPT_POST_ERROR_MSG = "There was an unknown problem while attempting to create your post."
let PROMPT_MEDIA_ERROR_TITLE = "Media Not Supported"
let PROMPT_MEDIA_ERROR_MSG = "Only images can be posted at this time. Please select an image to post!"
let PROMPT_PROFILE_ERROR_TITLE = "Unable To Update Profile"
let PROMPT_PROFILE_ERROR_MSG = "Updating of profile information was unsuccessful."

