//
//  PostCell.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/19/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import UIKit
import Alamofire
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage


class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg:UIImageView!
    @IBOutlet weak var postImage:UIImageView!
    @IBOutlet weak var likeImage:UIImageView!
    @IBOutlet weak var descriptionTxt: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    
    var post:PostItem?
    var request: Request?
    var gsReference: FIRStorageDownloadTask?
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        likeImage.userInteractionEnabled = true
        let action = #selector(onTapLike(_:))
        let gesture = UITapGestureRecognizer(target: self, action: action)
        likeImage.addGestureRecognizer(gesture)
    }
    
    override func drawRect(rect: CGRect)
    {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
        postImage.clipsToBounds = true
    }
    
    func configureCell(withPost post: PostItem, withImage img: UIImage?)
    {
        request?.cancel()
        gsReference?.cancel()
        postImage.image = nil
        
        self.post = post
        
        if let user = FIRAuth.auth()?.currentUser?.uid {
            BASE_REF.child(MessageFields.users).child(user).child(MessageFields.likes).child(post.postId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    self.likeImage.image = UIImage(named: "heart_no")
                } else {
                    self.likeImage.image = UIImage(named: "heart_yes")
                }
            })
        }
        
        descriptionTxt.text = post.postDescription
        likesLbl.text = "\(post.likes)"
        
        if let imageUrl = post.imageUrl {
            postImage.hidden = false
            if img != nil {
                postImage.image = img
            } else {
                if imageUrl.hasPrefix("gs://") {
                    self.gsReference = FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX){ (data, error) in
                        if let error = error {
                            print("Error downloading: \(error)")
                            return
                        }
                        self.postImage.image = UIImage.init(data: data!)
                        PostsVC.postImagesCache.setObject(self.postImage.image!, forKey: post.imageUrl!)
                    }
                } else {
                    request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, error in
                        guard error == nil else {
                            //print("error downloading image! \(error.debugDescription)")
                            return
                        }
                        if let data = data,
                            image = UIImage(data: data) {
                            self.postImage.image = image
                            PostsVC.postImagesCache.setObject(image, forKey: post.imageUrl!)
                        }
                    })
                }
            }
        } else {
            postImage.hidden = true
        }
    }
    
    @objc private func onTapLike(sender: UITapGestureRecognizer)
    {
        if let post = self.post, user = FIRAuth.auth()?.currentUser?.uid {
            var numOfLikes = post.likes
            BASE_REF.child(MessageFields.users).child(user).child(MessageFields.likes).child(post.postId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    BASE_REF.child(MessageFields.users).child(user).child(MessageFields.likes).child(post.postId).setValue(true, withCompletionBlock: { (error, ref) in
                        guard error == nil else {
                            // display error
                            return
                        }
                        self.updateLikes(numOfLikes)
                    })
                    numOfLikes = numOfLikes + 1
                } else {
                    BASE_REF.child(MessageFields.users).child(user).child(MessageFields.likes).child(post.postId).removeValueWithCompletionBlock({ (error, ref) in
                        guard error == nil else {
                            // display error
                            return
                        }
                        self.updateLikes(numOfLikes)
                    })
                    numOfLikes = (numOfLikes > 0) ? numOfLikes - 1 : 0
                }
            })
        }
    }
    
    private func updateLikes(likes: Int)
    {
        if let post = self.post {
            BASE_REF.child(MessageFields.posts).child(post.postId).child(MessageFields.likes).setValue(likes)
        }
    }
}
