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
import MBCircularProgressBar

class CameraViewController: UIViewController, ImageSaverDelegate, CameraEventDelegate, CaptureSettingsDelegate {

    var mCameraController: CameraController?
        
    var mSaveDialog: ImageViewController?
    
    @IBOutlet var mCameraButton: UIButton!
    @IBOutlet var mFpsLabel: UILabel!
    
    var mSettingsDialog: CaptureSettingsViewController?
    
    @IBOutlet var mIndeterminateProgressView: UILabel!
    @IBOutlet var mProgressView: MBCircularProgressBarView!
    var mCurrentCameraId: Int?
    
    @IBOutlet var mRecordingButton: UIButton?
    
    @IBAction func onModeTouch(_ sender: UIButton) {
        self.mCameraController?.tearDownPreview(self.view)
        DispatchQueue.global(qos: .default).async {
            self.mCameraController?.stopSession()
            
            let camera: GarbageCamera
            if (self.mCurrentCameraId == TileCam.ID) {
                let settings = StripCamSettings()
                camera = settings.makeCamera(settings:settings.getDefaultSettings())
            } else {
                let settings = TileCamSettings()
                camera = settings.makeCamera(settings:settings.getDefaultSettings())
            }
            self.mCurrentCameraId = camera.id
            
            self.mCameraController = CameraController(camera: camera, delegate: self, queueName: "com.estenh.GarbageCameraQueue")
            DispatchQueue.main.async {
                sender.setNeedsLayout()
                sender.setTitle("\(camera.title) >", for: .normal)
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
    
    @IBAction func switchCameraClicked(_ sender: UIButton) {
        mCameraController?.switchCamera()
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
            CATransaction.begin()
            button.layer.removeAllAnimations()
            CATransaction.commit()
            button.alpha = 0.8
            button.setImage(UIImage(named: "video"), for: UIControlState())
        }
    }
    
    func setButtonRecordingOn() {
        if let cameraButton = mCameraButton {
            cameraButton.isEnabled = false
        }
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

        let settings = TileCamSettings()
        let camera = settings.makeCamera(settings: settings.getDefaultSettings())
        // For grid capture
        mCameraController = CameraController(camera: camera, delegate: self, queueName: "com.estenh.GarbageCameraQueue")
         //*/
        // Do any additional setup after loading the view, typically from a nib.
        mCurrentCameraId = camera.id
        mCameraController!.setupSession(self.view)
        mProgressView.isHidden = true
        mIndeterminateProgressView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // This is garbage, garbageeee
        if let cameraButton = mCameraButton {
            cameraButton.isEnabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onRecordingFinished() {
        setButtonRecordingOff()
        mProgressView.value = 0
        mProgressView.isHidden = true
        mProgressView.setNeedsDisplay()
        
        mIndeterminateProgressView.text = ""
        mIndeterminateProgressView.isHidden = true
        mIndeterminateProgressView.setNeedsDisplay()

        showSaveDialog()
    }
    
    func onRecordingProgress(percent: Float) {
        if (percent == 0) { return }
        if let cameraController = mCameraController {
            if (cameraController.isRecording()) {
                mProgressView.isHidden = false
                let decimalPercent = 100 * percent
                mProgressView.value = CGFloat(decimalPercent)
            }
        }
    }
    
    func onRecordingProgress(frames: Int) {
        if (frames == 0) { return }
        if let cameraController = mCameraController {
            if (cameraController.isRecording() && mProgressView.isHidden) {
                mIndeterminateProgressView.isHidden = false
                let height = cameraController.getCurrentCaptureHeight()
                let size = "\(frames)x\(height)px"
                let textColor: UIColor
                let descriptor: String
                if (Double(frames) < Double(height) * 0.8) {
                    textColor = UIColor.red
                    descriptor = "too small"
                } else if (Double(frames) < Double(height) * 1.2) {
                    textColor = UIColor.orange
                    descriptor = "okay"
                } else {
                    textColor = UIColor.green
                    descriptor = "good"
                }
                mIndeterminateProgressView.textColor = textColor
                mIndeterminateProgressView.text = "\(size)\n(\(descriptor))"
            }
        }
    }
    
    func onCameraPrepared(fps: Float) {
        mFpsLabel.text = "\(Int(round(fps)))FPS"
        mCameraController?.startSession()
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
    
    @objc func photoSaved(_ photo: UIImage, didFinishSavingWithError: NSError?, contextInfo:UnsafeRawPointer) {
        if let error = didFinishSavingWithError {
            if (error.localizedDescription.count > 0) {
                if (AppSettings.isDebug()) {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            // Crashlytics.sharedInstance().recordError(error)
        }
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
        self.mCameraController?.tearDownPreview(self.view)
        DispatchQueue.global(qos: .default).async {
            self.mCameraController?.stopSession()
            self.mCameraController = CameraController.make(camera: settingsManager.makeCamera(settings: settings), delegate: self, controller: self.mCameraController, queueName: "com.estenh.GarbageCameraQueue")
            DispatchQueue.main.async {
                self.mCameraController!.setupSession(self.view)
            }
        }
    }
    
    func onSettingsFinished(settingsManager: CameraSettings, settings: [CameraSettings.SettingId: CameraSettings.OptionId]) {
        restartCamera(settingsManager: settingsManager, settings: settings)
        mSettingsDialog?.dismiss(animated: true, completion: nil)
        mSettingsDialog = nil
    }
}

