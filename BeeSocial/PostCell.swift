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
    @IBOutlet weak var cellIndicator: UIActivityIndicatorView!
    @IBOutlet weak var postAuthorLbl: UILabel!
    @IBOutlet weak var deleteImage: UIImageView!
    
    weak var delegate: DeletePostItemDelegate?
    
    var post:PostItem?
    private var requests = [AnyObject]()
    private var deleteGesture:UITapGestureRecognizer!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        likeImage.userInteractionEnabled = true
        let action = #selector(onTapLike(_:))
        let gesture = UITapGestureRecognizer(target: self, action: action)
        likeImage.addGestureRecognizer(gesture)
        
        let deleteAction = #selector(onTapDelete(_:))
        deleteGesture = UITapGestureRecognizer(target: self, action: deleteAction)
        deleteImage.addGestureRecognizer(deleteGesture)
        
        cellIndicator.hidden = true
        deleteImage.hidden = true
        deleteImage.userInteractionEnabled = true
    }
    
    override func drawRect(rect: CGRect)
    {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
        postImage.clipsToBounds = true
    }
    
    func configureCell(withPost post: PostItem, withImage img: UIImage?)
    {
        resetCellContents()
        self.post = post
        
        if let cachedLikeData = PostsVC.postDataCache.objectForKey("\(post.postId)\(CachedDataKeys.likeKeyNameSuffix)") as? Dictionary<String, Bool> {
            if let value = cachedLikeData[CachedDataKeys.postLiked] where value == true {
                likeImage.image = UIImage(named: "heart_yes")
            } else {
                likeImage.image = UIImage(named: "heart_no")
            }
        }
        
        if let user = FIRAuth.auth()?.currentUser?.uid {
            // if user owns post, display delete image
            if user == post.postedByUserId {
                deleteImage.hidden = false
            }
            
            var likeData = [String:Bool]()
            // get liked status
            BASE_REF.child(MessageFields.users).child(user).child(MessageFields.likes).child(post.postId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    self.likeImage.image = UIImage(named: "heart_no")
                    likeData[CachedDataKeys.postLiked] = false
                } else {
                    self.likeImage.image = UIImage(named: "heart_yes")
                    likeData[CachedDataKeys.postLiked] = true
                }
                PostsVC.postDataCache.setObject(likeData, forKey: "\(post.postId)\(CachedDataKeys.likeKeyNameSuffix)")
            })
            
            // get profile name/image of the original author
            
            if let userData = PostsVC.postDataCache.objectForKey(post.postId) as? Dictionary<String, String>,
                authorName = userData[CachedDataKeys.authorName],
                authorImgUrl = userData[CachedDataKeys.authorImgUrl] {
                
                self.postAuthorLbl.text = authorName
                configureProfileImage(imageUrl: authorImgUrl, completion: { (img, error) in
                    if error == nil {
                        self.profileImg.image = img
                    }
                })
            } else {
                var authorData = [String:String]()
                BASE_REF.child(MessageFields.posts).child(post.postId).child(MessageFields.postedbyUserId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                    if let userId = snapshot.value as? String {
                        BASE_REF.child(MessageFields.users).child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                            if let userDict = snapshot.value as? Dictionary<String, AnyObject> {
                                if let username = userDict[MessageFields.username] as? String {
                                    self.postAuthorLbl.text = username
                                    authorData[CachedDataKeys.authorName] = username
                                }
                                if let profileImgUrl = userDict[MessageFields.profileImgUrl] as? String {
                                    authorData[CachedDataKeys.authorImgUrl] = profileImgUrl
                                    
                                    self.configureProfileImage(imageUrl: profileImgUrl, completion: { (img, error) in
                                        if error == nil {
                                            self.profileImg.image = img
                                            self.profileImg.alpha = 0.0
                                            UIView.animateWithDuration(0.5, animations: {
                                                self.profileImg.alpha = 1.0
                                            })
                                        }
                                    })
                                }
                            }
                            PostsVC.postDataCache.setObject(authorData, forKey: post.postId)
                        })
                    }
                })
            }
        }
        
        descriptionTxt.text = post.postDescription
        likesLbl.text = "\(post.likes)"
        
        if let imageUrl = post.imageUrl {
            postImage.alpha = 0.0
            postImage.hidden = false
            if img != nil {
                postImage.image = img
                UIView.animateWithDuration(0.5, animations: { 
                    self.postImage.alpha = 1.0
                })
            } else {
                cellIndicator.hidden = false
                cellIndicator.startAnimating()
                
                loadAndSetImage(imageUrlStr: imageUrl, withCompletion: { (img, error) in
                    if error == nil {
                        self.postImage.image = img
                        self.cellIndicator.hidden = true
                        self.cellIndicator.stopAnimating()
                        UIView.animateWithDuration(0.5, animations: {
                            self.postImage.alpha = 1.0
                        })
                    }
                })
            }
        } else {
            postImage.hidden = true
        }
    }
    
    private func configureProfileImage(imageUrl url:String, completion: (img: UIImage?, error: NSError?) -> ())
    {
        let cachedImage: UIImage? = PostsVC.postDataCache.objectForKey(url) as? UIImage
        if cachedImage == nil {
            self.loadAndSetImage(imageUrlStr: url, withCompletion: { (img, error) in
                completion(img: img, error: error)
            })
        } else {
            completion(img: cachedImage, error: nil)
        }
    }
    
    @objc private func onTapDelete(sender: UITapGestureRecognizer)
    {
        if let post = post {
            delegate?.deletePostItem(post.postId)
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
    
    private func loadAndSetImage(imageUrlStr imageUrl: String, withCompletion callback: (img: UIImage?, error: NSError?) -> ())
    {
        if imageUrl.hasPrefix("gs://") {
            let ref = FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX) { (data, error) in
                if error == nil {
                    if let data = data,
                        loadedImage = UIImage(data: data) {
                        PostsVC.postDataCache.setObject(loadedImage, forKey: imageUrl)
                        callback(img: loadedImage, error: error)
                    }
                } else {
                    callback(img: nil, error: error)
                }
            }
            requests.append(ref)
        } else {
            let request = Alamofire.request(.GET, imageUrl).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, error in
                if error == nil {
                    if let data = data,
                        loadedImage = UIImage(data: data) {
                        PostsVC.postDataCache.setObject(loadedImage, forKey: imageUrl)
                        callback(img: loadedImage, error: error)
                    }
                } else {
                    callback(img: nil, error: error)
                }
            })
            requests.append(request)
        }
    }
    
    private func cancelAllRequests()
    {
        for item in requests {
            if item is Request {
                (item as! Request).cancel()
            } else if item is FIRStorageDownloadTask {
                (item as! FIRStorageDownloadTask).cancel()
            }
        }
        requests = [AnyObject]()
    }
    
    private func resetCellContents()
    {
        cancelAllRequests()
        deleteImage.hidden = true
        postAuthorLbl.text = ""
        cellIndicator.hidden = true
        cellIndicator.stopAnimating()
    }
    
    private func updateLikes(likes: Int)
    {
        if let post = self.post {
            BASE_REF.child(MessageFields.posts).child(post.postId).child(MessageFields.likes).setValue(likes)
        }
    }
}
