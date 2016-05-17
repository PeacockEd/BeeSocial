//
//  MaterialButton.swift
//  BeeSocial
//
//  Created by Edward P. Kelly on 5/16/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import UIKit

class MaterialButton: UIButton {
    
    override func awakeFromNib()
    {
        AppUtils.addMaterialness(toLayer: layer)
    }
}
