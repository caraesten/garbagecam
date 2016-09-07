//
//  ImageViewController.swift
//  StripCam
//
//  Created by Esten Hurtle on 8/21/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit

class ImageViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    var imageTaken: UIImage?
    
    var imageSaver: ImageSaverDelegate?
    
    @IBAction func discardClicked(sender: UIButton) {
        self.imageSaver?.onDismissed()
    }
    @IBAction func saveClicked(sender: UIButton) {
        self.imageSaver?.onSaved()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = imageTaken {
            imageView.image = image
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setImage(image: UIImage, delegate: ImageSaverDelegate) {
        imageTaken = image
        imageSaver = delegate
        if let view = imageView {
            view.image = image
        }
    }
}

protocol ImageSaverDelegate {
    func onSaved()
    func onDismissed()
}