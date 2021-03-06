//
//  PostsVC.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/19/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import Firebase
import FirebaseDatabase
import FirebaseStorage


protocol DeletePostItemDelegate: class {
    func deletePostItem(postId: String)
}


class PostsVC: UIViewController, UITableViewDelegate, UITableViewDataSource,
UIImagePickerControllerDelegate, UINavigationControllerDelegate, DeletePostItemDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postTextField: MaterialTextField!
    @IBOutlet weak var selectImageIcon: UIImageView!
    @IBOutlet weak var activityView:LoadingIndicatorView!
    @IBOutlet weak var postButton:UIButton!
    @IBOutlet weak var postActivityView:UIActivityIndicatorView!
    
    private var refHandle:FIRDatabaseHandle?
    static var postDataCache = NSCache()
    
    private var settingsVC: ProfileSettingsVC!
    private var imageSelected = false
    private var imagePicker:UIImagePickerController!
    private var postData = [PostItem]()
    
    private var isPostingMessage = false
    
    var newUser = false
    var loginManager: LoginManager?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        UINavigationBar.appearance().tintColor = UIColor(red: 78/255.0, green: 52/255.0, blue: 46/255.0, alpha: 1.0)
        
        NSNotificationCenter.defaultCenter().addObserverForName(NotificationKeys.signedOut, object: nil, queue: nil) { notification in
            self.performSegueWithIdentifier("unwindToLogin", sender: nil)
        }
        
        postActivityView.hidden = true
        self.title = AppState.sharedInstance.displayName
        
        activityView.statusTxt = "Hang tight! We're retrieving data."
        activityView.hidden = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 373
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.navigationBar.tintColor = nil
        
        settingsVC = ProfileSettingsVC()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        self.navigationController?.navigationBar.topItem?.title = ""
        
        let query = BASE_REF.child(MessageFields.posts).queryOrderedByChild("timestamp")
        refHandle = query.observeEventType(.Value, withBlock: { (snapshot) in
            self.postData = []
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for item in snapshots {
                    if let postDict = item.value as? Dictionary<String, AnyObject> {
                        let id = item.key
                        let post = PostItem(postId: id, data: postDict)
                        self.postData.append(post)
                    }
                }
                self.postData = self.postData.reverse()
                self.tableView.reloadData()
                self.activityView.hidden = true
            }
        })
        
        if newUser {
            newUser = false
            performSegueWithIdentifier(SEGUE_PROFILE_INFO, sender: nil)
        }
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        if let handle = refHandle {
            BASE_REF.removeObserverWithHandle(handle)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return postData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let post = postData[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            
            var image:UIImage?
            if let url = post.imageUrl {
                image = PostsVC.postDataCache.objectForKey(url) as? UIImage
            }
            cell.configureCell(withPost: post, withImage: image)
            cell.delegate = self
            
            return cell
        } else {
            return PostCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        if postData[indexPath.row].imageUrl == nil {
            return 158
        }
        return tableView.estimatedRowHeight
    }
    
    private func sendMessage(post data:[String: AnyObject])
    {
        var messageData = data
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        // let defaultTimeZoneStr = formatter.stringFromDate(date)
        // : "2016-05-10 20:55:06 +0300" - Local (GMT +3)
        formatter.timeZone = NSTimeZone(abbreviation: "UTC")
        let utcTimeZoneStr = formatter.stringFromDate(date)
        // : "2016-05-10 17:55:06 +0000" - UTC Time
        messageData[MessageFields.timestamp] = utcTimeZoneStr
        
        if let user = FIRAuth.auth()?.currentUser {
            messageData[MessageFields.postedbyUserId] = user.uid
            if imageSelected && selectImageIcon.image != nil {
                let thumbImage = AppUtils.generateThumbnailFromImage(selectImageIcon.image!, intoSize: POST_IMAGE_SIZE)
                let thumbPath = AppUtils.saveImageToDocumentsAndReturnPath(thumbImage, withFilename: "\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))-asset.png")
                
                guard thumbPath != nil else {
                    AppUtils.showErrorPromptInVC(self, withTitle: PROMPT_IMAGE_ERROR_TITLE, withMsg: PROMPT_IMAGE_ERROR_MSG, onDismissPrompt: nil)
                    return
                }
                
                let filePath = "\(user.uid)/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))/asset.png"
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                
                BASE_STORAGE_REF.child(filePath)
                    .putFile(thumbPath!, metadata: metadata) { (metadata, error) in
                        guard error == nil else {
                            //print("Error uploading image. \(error.debugDescription)")
                            AppUtils.showErrorPromptInVC(self, withTitle: PROMPT_IMAGE_ERROR_TITLE, withMsg: PROMPT_IMAGE_ERROR_MSG, onDismissPrompt: nil)
                            return
                        }
                        messageData[MessageFields.imageUrl] = BASE_STORAGE_REF.child((metadata?.path)!).description
                        BASE_REF.child(MessageFields.posts).childByAutoId().setValue(messageData, andPriority: nil, withCompletionBlock: self.onPostCommitted)
                        self.selectImageIcon.image = UIImage(named: "camera.png")
                        self.imageSelected = false
                }
            } else {
                BASE_REF.child(MessageFields.posts).childByAutoId().setValue(messageData, andPriority: nil, withCompletionBlock: onPostCommitted)
            }
        } else {
            AppUtils.showErrorPromptInVC(self, withTitle: PROMPT_POST_ERROR_TITLE, withMsg: PROMPT_POST_ERROR_MSG, onDismissPrompt: nil)
        }
    }
    
    private func onPostCommitted(error: NSError?, reference: FIRDatabaseReference)
    {
        if error == nil, let user = FIRAuth.auth()?.currentUser?.uid {
            BASE_REF.child(MessageFields.users).child(user).child(MessageFields.posts).child(reference.key).setValue(true, andPriority: nil, withCompletionBlock: { (error, ref) in
                guard error == nil else {
                    // New post created, but unable to be
                    // associated with the user in the user's
                    // posts array.
                    return
                }
                self.isPostingMessage = false
                self.postButton.hidden = false
                self.postActivityView.stopAnimating()
                self.postActivityView.hidden = true
                self.postTextField.text = ""
            })
        }
    }
    
    private func showMediaError()
    {
        AppUtils.showErrorPromptInVC(self, withTitle: PROMPT_MEDIA_ERROR_TITLE, withMsg: PROMPT_MEDIA_ERROR_MSG, onDismissPrompt: nil)
    }
    
    private func onConfirmDeletePostItem(postId: String)
    {
        BASE_REF.child(MessageFields.posts).child(postId).removeValueWithCompletionBlock { (error, ref) in
            // done!
        }
    }
    
    @IBAction func onTapLogout(sender: AnyObject)
    {
        loginManager?.logout()
    }
    
    @IBAction func onTapSettings(sender: AnyObject)
    {
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    @IBAction func onTapPost(sender: AnyObject)
    {
        isPostingMessage = true
        postButton.hidden = true
        postActivityView.hidden = false
        postActivityView.startAnimating()
        
        let message: [String : AnyObject] = [MessageFields.description: postTextField.text ?? "", MessageFields.likes: 0]
        sendMessage(post: message)
    }
    
    @IBAction func onTapSelectImage(sender: AnyObject)
    {
        if isPostingMessage {
            return
        }
        presentViewController(imagePicker, animated: true, completion: nil)
    }
}

extension PostsVC {
    
    func deletePostItem(postId: String) {
        AppUtils.showConfirmationPromptInVC(self, withTitle: "Delete Post", withMsg: "Are you sure you want to delete this post? This cannot be undone!") { action in
            if let ok = action.title where ok == "OK" {
                self.onConfirmDeletePostItem(postId)
            }
        }
    }
}

extension PostsVC {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        var mediaNotSupported: (() -> Void)? = nil
        
        switch info[UIImagePickerControllerMediaType] as! NSString {
        case kUTTypeImage:
            if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                imageSelected = true
                selectImageIcon.image = selectedImage
                //selectedImageURL = info[UIImagePickerControllerReferenceURL] as? NSURL
            }
            break
        default:
            mediaNotSupported = self.showMediaError
            selectImageIcon.image = UIImage(named: "camera.png")
            break
        }
        imagePicker.dismissViewControllerAnimated(true, completion: mediaNotSupported)
    }
}