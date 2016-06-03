//
//  LoadingIndicatorView.swift
//  BeeSocial
//
//  Created by Ed Kelly on 6/3/16.
//  Copyright © 2016 Edward P. Kelly. All rights reserved.
//

import UIKit

class LoadingIndicatorView: UIView {
    
    @IBOutlet weak var spinner:UIActivityIndicatorView!
    @IBOutlet weak var statusLabel:UILabel!
    
    private var _statusTxt:String!
    
    var statusTxt:String {
        get {
            if _statusTxt == nil {
                _statusTxt = "Loading..."
            }
            return _statusTxt
        }
        set {
            _statusTxt = newValue
            statusLabel.text = statusTxt
        }
    }
    
    override func awakeFromNib() {
        self.addObserver(self, forKeyPath: "hidden", options: [], context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if (self.hidden) {
            stopAnimating()
        } else {
            startAnimating()
        }
    }
    
    func startAnimating()
    {
        statusLabel.text = statusTxt
        spinner.startAnimating()
    }
    
    func stopAnimating()
    {
        spinner.stopAnimating()
    }
}
