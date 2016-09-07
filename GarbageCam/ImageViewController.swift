//
//  ImageViewController.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 8/21/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit

class ImageViewController: UIViewController {
    @IBOutlet var mImageView: UIImageView!
    
    private var mImageTaken: UIImage?
    
    private var mImageSaver: ImageSaverDelegate?
    
    @IBAction func discardClicked(sender: UIButton) {
        self.mImageSaver?.onDismissed()
    }
    
    @IBAction func saveClicked(sender: UIButton) {
        self.mImageSaver?.onSaved()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = mImageTaken {
            mImageView.image = image
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setImage(image: UIImage, delegate: ImageSaverDelegate) {
        mImageTaken = image
        mImageSaver = delegate
        if let view = mImageView {
            view.image = image
        }
    }
}

protocol ImageSaverDelegate {
    func onSaved()
    func onDismissed()
}