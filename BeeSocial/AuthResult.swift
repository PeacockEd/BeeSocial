//
//  AuthResult.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/17/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation

public enum AuthResult<Value, AuthError> {
    
    case Success(Value)
    case Failure(AuthError)
    
    public var value:Value?
    {
        switch self {
        case .Success(let value):
            return value
        case .Failure:
            return nil
        }
    }
    
    public var error:AuthError?
    {
        switch self {
        case .Success:
            return nil
        case .Failure(let error):
            return error
        }
    }
}