//
//  AppUtils.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/16/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import Foundation
import UIKit

class AppUtils {
    
    static func addMaterialness(toLayer layer:CALayer)
    {
        layer.cornerRadius = 2.0
        layer.shadowColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.5).CGColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 5.0
        layer.shadowOffset = CGSizeMake(0.0, 2.0)
    }
    
    static func imageWithImage(image: UIImage, scaledToSize newSize:CGSize) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func getScaleForProportionalResize(originalSize: CGSize, intoSize: CGSize, onlyScaleDown: Bool) -> CGFloat
    {
        let sx: CGFloat = originalSize.width
        let sy: CGFloat = originalSize.height
        var dx: CGFloat = intoSize.width
        var dy: CGFloat = intoSize.height
        var scale: CGFloat = 1.0
        
        if sx != 0 && sy != 0 {
            dx = dx / sx
            dy = dy / sy
            scale = min(dx, dy)// (dx > dy) ? dx : dy
        }
        
        if scale > 1 && onlyScaleDown {
            scale = 1.0
        }
        
        return scale
    }
    
    static func saveImageToDocumentsAndReturnPath(image: UIImage?, withFilename filename: String) -> NSURL?
    {
        var imageUrl: NSURL?
        if image != nil {
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let path = (paths[0] as NSString).stringByAppendingPathComponent("\(filename)")
            let data = UIImagePNGRepresentation(image!)
            do {
                try data?.writeToFile(path, options: .AtomicWrite)
            } catch {
                // TODO: Handle error in some way
            }
            imageUrl = NSURL(fileURLWithPath: path)
        }
        return imageUrl
    }
    
    static func generateThumbnailFromImage(image: UIImage, intoSize size:CGSize) -> UIImage?
    {
        var thumbImage:UIImage? = nil
        
        if let imageData = UIImagePNGRepresentation(image) {
            //let size = image.size
            let scale = AppUtils.getScaleForProportionalResize(image.size, intoSize: size, onlyScaleDown: true)
            var _thumb_image: UIImage!
            if scale < 1 {
                _thumb_image = AppUtils.imageWithImage(UIImage(data: imageData)!, scaledToSize: CGSizeMake(image.size.width * scale, image.size.height * scale))
            } else {
                _thumb_image = image
            }
            thumbImage = _thumb_image
        }
        
        return thumbImage
    }
}