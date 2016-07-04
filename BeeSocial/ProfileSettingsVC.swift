//
//  ProfileSettingsVC.swift
//  BeeSocial
//
//  Created by Ed Kelly on 6/21/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation
import UIKit
import Photos
import MobileCoreServices
import FirebaseAuth
import FirebaseStorage

class ProfileSettingsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var profileImage: UIImageView!
    
    private var imageSelected = false
    private var imagePicker: UIImagePickerController!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.navigationBar.tintColor = nil
        
        profileImage.userInteractionEnabled = true
        let imageGesture = UITapGestureRecognizer(target: self, action: #selector(onImageTapped(_:)))
        profileImage.addGestureRecognizer(imageGesture)
        
        if let displayName = AppState.sharedInstance.displayName {
            nameTextField.text = displayName
        }
        
        profileImage.image = loadProfileImage() ?? UIImage(named: "camera.png")
    }
    
    @objc private func onImageTapped(sender: UITapGestureRecognizer)
    {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    private func loadProfileImage() -> UIImage?
    {
        var image: UIImage?
        if let user = FIRAuth.auth()?.currentUser {
            let filename = "\(user.uid)\(PROFILE_IMAGE_FILE_SUFFIX)"
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let dir = paths[0]
            let path = (dir as NSString).stringByAppendingPathComponent(filename)
            image = UIImage(contentsOfFile: path)
        }
        return image
    }
    
    private func updateProfile(displayName: String?, completionBlock: (() -> ())?)
    {
        if let user = FIRAuth.auth()?.currentUser {
            func updateUsername()
            {
                if let name = displayName {
                    let changeRequest = user.profileChangeRequest()
                    changeRequest.displayName = name
                    changeRequest.commitChangesWithCompletion { error in
                        guard error == nil else {
                            // TODO: Display error
                            return
                        }
                        AppState.sharedInstance.displayName = name
                        BASE_REF.child(MessageFields.users).child(user.uid).child(MessageFields.username).setValue(name, withCompletionBlock: { (error, dbRef) in
                            completionBlock?()
                            print("UPDATE USER NAME")
                        })
                    }
                } else {
                    print("NO USER NAME!")
                    completionBlock?()
                }
            }
            
            if imageSelected {
                func uploadImage()
                {
                    guard profileImage.image != nil else {
                        // TODO Handle error
                        updateUsername()
                        return
                    }
                    let thumbPath = AppUtils.saveImageToDocumentsAndReturnPath(profileImage.image, withFilename: "\(user.uid)\(PROFILE_IMAGE_FILE_SUFFIX)")
                    
                    guard thumbPath != nil else {
                        // TODO: Display error
                        updateUsername()
                        return
                    }
                    
                    let filePath = "\(user.uid)/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))/\(thumbPath!.lastPathComponent!)"
                    let metadata = FIRStorageMetadata()
                    metadata.contentType = "image/*"
                    
                    BASE_STORAGE_REF.child(filePath)
                        .putFile(thumbPath!, metadata: metadata) { (metadata, error) in
                            guard error == nil else {
                                print("Error uploading image. \(error.debugDescription)")
                                // TODO: Display error
                                updateUsername()
                                return
                            }
                            BASE_REF.child(MessageFields.users).child(user.uid).child(MessageFields.profileImgUrl).setValue(BASE_STORAGE_REF.child((metadata?.path)!).description)
                    }
                    updateUsername()
                }
                
                BASE_REF.child(MessageFields.users).child(user.uid).child(MessageFields.profileImgUrl).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                    if let _ = snapshot.value as? NSNull {
                        uploadImage()
                    } else {
                        if let path = snapshot.value as? String {
                            let ref = BASE_STORAGE_REF.storage.referenceForURL(path)
                            ref.deleteWithCompletion { error in
                                print("Error: \(error.debugDescription)")
                                print("PATH TO DELETE: \(path)")
                                uploadImage()
                            }
                        }
                    }
                })
            } else {
                print("NO IMAGE!")
                updateUsername()
            }
        }
    }
    
    @IBAction func onTapSave(sender: AnyObject)
    {
        updateProfile(nameTextField.text) {
            self.profileImage.image = self.loadProfileImage() ?? UIImage(named: "camera.png")
        }
    }
    
    @IBAction func onTapCancel(sender: AnyObject)
    {
        navigationController?.popViewControllerAnimated(true)
    }
}

extension ProfileSettingsVC {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        switch info[UIImagePickerControllerMediaType] as! NSString {
        case kUTTypeImage:
            if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                if let thumbImage = AppUtils.generateThumbnailFromImage(selectedImage, intoSize: PROFILE_THUMB_SIZE) {
                    imageSelected = true
                    profileImage.image = thumbImage
                }
            }
            break
        default:
            // display a friendly reminder that media (i.e. movies)
            // other than images are not supported
            break
        }
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
    }
}
