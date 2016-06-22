//
//  PostItem.swift
//  BeeSocial
//
//  Created by Ed Kelly on 6/2/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation

class PostItem {
    private var _postDescription:String!
    private var _imageUrl:String?
    private var _likes:Int!
    private var _username:String!
    private var _postId:String!
    
    var postDescription: String
    {
        return _postDescription
    }
    
    var imageUrl: String?
    {
        return _imageUrl
    }
    
    var likes: Int
    {
        return _likes
    }
    
    var username: String
    {
        return _username
    }
    
    var postId: String
    {
        return _postId
    }
    
    init(postId:String, data:Dictionary<String, AnyObject>)
    {
        self._postId = postId
        
        if let likes = data[MessageFields.likes] as? Int {
            self._likes = likes
        }
        if let imageUrl = data[MessageFields.imageUrl] as? String {
            self._imageUrl = imageUrl
        }
        if let description = data[MessageFields.description] as? String {
            self._postDescription = description
        }
    }
}
