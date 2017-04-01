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
    
    fileprivate var mImageTaken: UIImage?
    
    fileprivate var mImageSaver: ImageSaverDelegate?
    
    @IBAction func discardClicked(_ sender: UIButton) {
        self.mImageSaver?.onDismissed()
    }
    
    @IBAction func saveClicked(_ sender: UIButton) {
        self.mImageSaver?.onSaved()
    }
    
    @IBAction func shareClicked(_ sender: UIButton) {
        if let image = mImageTaken {
            let text = "#GarbageCam"
            let activityViewController = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.completionWithItemsHandler = {(activityType, completed, returnedItems, error) in
                if (completed) {
                    self.mImageSaver?.onSaved()
                }
            }

            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = mImageTaken {
            mImageView.image = image
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setImage(_ image: UIImage, delegate: ImageSaverDelegate) {
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
