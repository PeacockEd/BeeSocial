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
    
    private var profileImageUrl:NSURL?
    private var imagePicker: UIImagePickerController!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
    }
    
    private func updateProfile(displayName: String?, profileImage: UIImage?)
    {
        if let user = FIRAuth.auth()?.currentUser {
            let changeRequest = user.profileChangeRequest()
            if let name = displayName {
                changeRequest.displayName = name
            }
            if let imageUrl = profileImageUrl {
                let assets = PHAsset.fetchAssetsWithALAssetURLs([imageUrl], options: nil)
                let asset = assets.firstObject
                asset?.requestContentEditingInputWithOptions(nil, completionHandler: { (input, info) in
                    if let imageFile = input?.fullSizeImageURL, auth = FIRAuth.auth()?.currentUser?.uid {
                        let filePath = "\(auth)/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))/\(imageUrl.lastPathComponent!)"
                        let metadata = FIRStorageMetadata()
                        metadata.contentType = "image/jpeg"
                        BASE_STORAGE_REF.child(filePath)
                            .putFile(imageFile, metadata: metadata) { (metadata, error) in
                                guard error == nil else {
                                    print("Error uploading image. \(error.debugDescription)")
                                    // TODO: Display error
                                    return
                                }
                                changeRequest.photoURL = NSURL(string: BASE_STORAGE_REF.child((metadata?.path)!).description)
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func onTapSave(sender: AnyObject)
    {
        
    }
    
    @IBAction func onTapCancel(sender: AnyObject)
    {
        
    }
}

extension ProfileSettingsVC {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        switch info[UIImagePickerControllerMediaType] as! NSString {
        case kUTTypeImage:
            if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                profileImage.image = selectedImage
                profileImageUrl = info[UIImagePickerControllerReferenceURL] as? NSURL
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
