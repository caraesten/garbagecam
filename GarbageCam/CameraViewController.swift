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

class CameraViewController: UIViewController, ImageSaverDelegate, CameraEventDelegate, CaptureSettingsDelegate {
    var mCameraController: CameraController?
        
    var mSaveDialog: ImageViewController?
    
    var mSettingsDialog: CaptureSettingsViewController?
    
    var mCurrentCameraId: Int?
    
    @IBOutlet var mRecordingButton: UIButton?
    
    @IBAction func onModeTouch(_ sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            self.mCameraController?.tearDownPreview(self.view)
            self.mCameraController?.stopSession()
            
            // TODO: persist settings per camera
            let camera: GarbageCamera
            if (self.mCurrentCameraId == TileCam.ID) {
                camera = StripCam()
            } else {
                camera = TileCam(columns: 40, rows: 40, randomCapture: false)
            }
            self.mCurrentCameraId = camera.id
            sender.setNeedsLayout()
            
            self.mCameraController = CameraController(camera: camera, delegate: self, queueName: "com.estenh.GarbageCameraQueue")
            DispatchQueue.main.async {
                sender.titleLabel?.text = camera.title
                self.mCameraController!.setupSession(self.view)
                self.mCameraController!.startSession()
            }
        }
    }
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
    
    @IBAction func settingsClicked(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CaptureSettingsViewController") as! CaptureSettingsViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.delegate = self
        vc.settings = mCameraController?.currentCamera.settings
        mSettingsDialog = vc
        present(vc, animated: true, completion: nil)
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

        let camera = TileCam(columns: 40, rows: 40, randomCapture: false)
        // For grid capture
        mCameraController = CameraController(camera: camera, delegate: self, queueName: "com.estenh.GarbageCameraQueue")
         //*/
        // Do any additional setup after loading the view, typically from a nib.
        mCurrentCameraId = camera.id
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
        mSaveDialog = nil
    }
    
    func resetRecorder() {
        mCameraController!.clearData()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func restartCamera(settingsManager: CameraSettings, settings: [CameraSettings.SettingId: CameraSettings.OptionId]) {
        DispatchQueue.global(qos: .default).async {
            self.mCameraController?.tearDownPreview(self.view)
            self.mCameraController?.stopSession()
            self.mCameraController = CameraController(camera: settingsManager.makeCamera(settings: settings), delegate: self, queueName: "com.estenh.GarbageCameraQueue")
            DispatchQueue.main.async {
                self.mCameraController!.setupSession(self.view)
                self.mCameraController!.startSession()
            }
        }
    }
    
    func onSettingsFinished(settingsManager: CameraSettings, settings: [CameraSettings.SettingId: CameraSettings.OptionId]) {
        restartCamera(settingsManager: settingsManager, settings: settings)
        mSettingsDialog?.dismiss(animated: true, completion: nil)
        mSettingsDialog = nil
    }
}

