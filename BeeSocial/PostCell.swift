//
//  PostCell.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/19/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import UIKit
import Alamofire

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg:UIImageView!
    @IBOutlet weak var postImage:UIImageView!
    
    @IBOutlet weak var descriptionTxt: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    
    var request: Request?
    

    override func awakeFromNib()
    {
        super.awakeFromNib()
    }
    
    override func drawRect(rect: CGRect)
    {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
        postImage.clipsToBounds = true
    }

    func configureCell(withPost post:PostItem, withImage img:UIImage?)
    {
        request?.cancel()
        
        descriptionTxt.text = post.postDescription
        likesLbl.text = "\(post.likes)"
        
        if post.imageUrl != nil {
            if img != nil {
                print("CACHED!")
                postImage.image = img
            } else {
                request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, error in
                    guard error == nil else {
                        return
                    }
                    if let data = data,
                        image = UIImage(data: data) {
                        self.postImage.image = image
                        PostsVC.postImagesCache.setObject(image, forKey: post.imageUrl!)
                    }
                })
            }
        } else {
            postImage.hidden = true
        }
    }
}
