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
    
    @IBOutlet var mRecordingButton: UIButton?
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        if (mCameraController!.toggleRecording()) {
            setButtonRecordingOn()
        } else {
            setButtonRecordingOff()
        }
    }
    
    @IBAction func lockClicked(_ sender: UIButton) {
        if (mCameraController!.toggleExposureLock()) {
            sender.tintColor = UIColor.blue
        } else {
            sender.tintColor = UIColor.white
        }
    }
    
    func setButtonRecordingOff() {
        if let button = mRecordingButton {
            // TODO: this is still not working sometimes, no clue why
            CATransaction.begin()
            button.layer.removeAllAnimations()
            CATransaction.commit()
            button.alpha = 0.8
            button.setImage(UIImage(named: "video"), for: UIControlState())
        }
    }
    
    func setButtonRecordingOn() {
        if let button = mRecordingButton {
            button.setImage(UIImage(named: "novideo"), for: UIControlState())
            UIView.animate(withDuration: 1, delay: 0, options: [.repeat, .autoreverse, .beginFromCurrentState, .allowUserInteraction], animations: {() in
                button.alpha = 0.5;
                }, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*mCameraController = CameraController(processor: StripProcessor(), captureProcessor: StripCaptureProcessor(), delegate: self, queueName: "com.estenh.GarbageCameraQueue")*/

        // For grid capture
        mCameraController = CameraController(processor: TileProcessor(columns: 40, rows: 40), captureProcessor: TileCaptureProcessor(columns: 40, rows: 40), delegate: self, queueName: "com.estenh.GarbageCameraQueue")
         //*/
        // Do any additional setup after loading the view, typically from a nib.
        mCameraController!.setupSession(self.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mCameraController!.startSession()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onRecordingFinished() {
        setButtonRecordingOff()
        showSaveDialog()
    }
    
    func showSaveDialog() {
        if let image = mCameraController!.processedImage {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let imageViewController = storyboard.instantiateViewController(withIdentifier: "ImageViewController") as! ImageViewController
            imageViewController.setImage(image, delegate: self)
            DispatchQueue.main.async {
                self.present(imageViewController, animated: true, completion: nil)
            }
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
    
    func photoSaved(_ photo: UIImage, didFinishSavingWithError: NSError?, contextInfo:UnsafeRawPointer) {
        onDismissed()
    }
    
    func onDismissed() {
        resetRecorder()
        mSaveDialog?.dismiss(animated: true, completion: nil)
    }
    
    func resetRecorder() {
        mCameraController!.clearData()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

