//
//  DataProxy.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/17/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation
import Firebase

class DataProxy {
    
    static let instance = DataProxy()
    
    private var _BASE_FB_REF = Firebase(url: "https://beesocial.firebaseio.com")
    
    var BASE_FB_REF: Firebase
    {
        return _BASE_FB_REF
    }
}