//
//  ViewController.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 8/21/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import UIKit
import AVFoundation
import CoreVideo
import CoreGraphics

class CameraViewController: UIViewController, ImageSaverDelegate, CameraEventDelegate {
    var mCameraController: CameraController?
        
    var mSaveDialog: ImageViewController?
    
    @IBAction func buttonClicked(sender: UIButton) {
        if (mCameraController!.toggleRecording()) {
            sender.setImage(UIImage(named: "novideo"), forState: UIControlState.Normal)
            UIView.animateWithDuration(1, delay: 0, options: [.Repeat, .Autoreverse, .BeginFromCurrentState, .AllowUserInteraction], animations: {() in
                sender.alpha = 0.5;
                }, completion: nil)
        } else {
            sender.layer.removeAllAnimations()
            sender.alpha = 0.8
            sender.setImage(UIImage(named: "video"), forState: UIControlState.Normal)
        }
    }
    
    @IBAction func lockClicked(sender: UIButton) {
        if (mCameraController!.toggleExposureLock()) {
            sender.tintColor = UIColor.blueColor()
        } else {
            sender.tintColor = UIColor.whiteColor()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mCameraController = CameraController(processor: StripProcessor(), captureProcessor: StripCaptureProcessor(), delegate: self, queueName: "com.estenh.GarbageCameraQueue")
        // Do any additional setup after loading the view, typically from a nib.
        mCameraController!.setupSession(self.view)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        mCameraController!.startSession()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onRecordingFinished() {
        showSaveDialog()
    }
    
    func showSaveDialog() {
        if let image = mCameraController!.processedImage {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let imageViewController = storyboard.instantiateViewControllerWithIdentifier("ImageViewController") as! ImageViewController
            imageViewController.setImage(image, delegate: self)
            presentViewController(imageViewController, animated: true, completion: nil)
            mSaveDialog = imageViewController
        }
    }
    
    func onSaved() {
        if let image = mCameraController!.processedImage {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(CameraViewController.photoSaved(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            onDismissed()
        }
    }
    
    func photoSaved(photo: UIImage, didFinishSavingWithError: NSError?, contextInfo:UnsafePointer<Void>) {
        onDismissed()
    }
    
    func onDismissed() {
        resetRecorder()
        mSaveDialog?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func resetRecorder() {
        mCameraController!.clearData()
    }
}

