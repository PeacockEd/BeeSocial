//
//  PostsVC.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/19/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class PostsVC: UIViewController, UITableViewDelegate, UITableViewDataSource,
        UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postTextField: MaterialTextField!
    @IBOutlet weak var selectImageIcon: UIImageView!
    @IBOutlet weak var activityView:LoadingIndicatorView!
    
    private var ref:FIRDatabaseReference!
    private var refHandle:FIRDatabaseHandle?
    static var postImagesCache = NSCache()
    
    private var imagePicker:UIImagePickerController!
    private var postData = [PostItem]()
    
    var loginManager: LoginManager?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserverForName(NotificationKeys.signedOut, object: nil, queue: nil) { notification in
            self.performSegueWithIdentifier("unwindToLogin", sender: nil)
        }
        
        self.title = AppState.sharedInstance.displayName
        
        activityView.statusTxt = "Hang tight! We're retrieving data."
        activityView.hidden = false

        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 373
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        ref = FIRDatabase.database().reference()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        refHandle = ref.child(MessageFields.posts).observeEventType(.Value, withBlock: { (snapshot) in
            self.postData = []
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for item in snapshots {
                    if let postDict = item.value as? Dictionary<String, AnyObject> {
                        let id = item.key
                        let post = PostItem(postId: id, data: postDict)
                        self.postData.append(post)
                    }
                }
                self.tableView.reloadData()
                self.activityView.hidden = true
            }
        })
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        if let handle = refHandle {
            ref.removeObserverWithHandle(handle)
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
                image = PostsVC.postImagesCache.objectForKey(url) as? UIImage
            }
            cell.configureCell(withPost: post, withImage: image)
            
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
    
    @IBAction func onTapLogout(sender: AnyObject)
    {
        loginManager?.logout()
    }
    
    @IBAction func onTapPost(sender: AnyObject)
    {
        
    }
    
    @IBAction func onTapSelectImage(sender: AnyObject)
    {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
}

extension PostsVC {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        selectImageIcon.image = image
    }
}
