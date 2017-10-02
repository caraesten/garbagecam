//
//  CameraController.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/7/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreVideo
import CoreGraphics
import Crashlytics

class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let DEFAULT_QUEUE_NAME = "com.estenh.GarbageCameraQueue"
    
    var processedImage:UIImage? {
        get {
            if (mIsRecording || mCurrentData.isEmpty) {
                return nil
            }
            if let processed = mFinalImage {
                return processed
            } else {
                mFinalImage = processImages()
                return mFinalImage!
            }
        }
    }
    
    let currentCamera: GarbageCamera
    
    fileprivate let mQueue: DispatchQueue
    fileprivate let mQueueName: String
    fileprivate let mProcessor: ImageProcessor
    fileprivate let mCaptureProcessor: CaptureProcessor
    fileprivate let mDelegate: CameraEventDelegate
    
    fileprivate var mIsRecording:Bool = false
    fileprivate var mIsExposureLocked:Bool = false
    fileprivate var mCurrentData:[UIImage] = [UIImage]()
    fileprivate var mFinalImage:UIImage?
    fileprivate var mCaptureDevice: AVCaptureDevice?
    fileprivate var mPreviewLayer: CALayer?
    
    fileprivate lazy var cameraSession: AVCaptureSession = {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let s = AVCaptureSession()
        return s
    }()
    
    class func make(camera: GarbageCamera, delegate: CameraEventDelegate, controller: CameraController?, queueName: String?) -> CameraController {
        let cameraController = CameraController(camera: camera, delegate: delegate, queueName: queueName)
        if let camCtrl = controller {
            cameraController.mCaptureDevice = camCtrl.mCaptureDevice
        }
        return cameraController
    }
    
    init(camera: GarbageCamera, delegate: CameraEventDelegate, queueName: String?) {
        if let qn = queueName {
            mQueueName = qn
        } else {
            mQueueName = CameraController.DEFAULT_QUEUE_NAME
        }
        mQueue = DispatchQueue(label: mQueueName, attributes: [])
        mProcessor = camera.imageProcessor
        mCaptureProcessor = camera.captureProcessor
        mDelegate = delegate
        currentCamera = camera
    }
    
    func startSession() {
        cameraSession.startRunning()
    }
    
    func stopSession() {
        cameraSession.stopRunning()
    }
    
    func processImages() -> UIImage {
        return mProcessor.process(mCurrentData)
    }
    
    func tearDownPreview(_ view: UIView) {
        if let oldLayer = mPreviewLayer {
            oldLayer.removeFromSuperlayer()
        }
    }
    
    func switchCamera() {
        cameraSession.beginConfiguration()
        cameraSession.sessionPreset = AVCaptureSessionPresetHigh
        if let input = cameraSession.inputs[0] as? AVCaptureDeviceInput {
            cameraSession.removeInput(input)
            if let newCam = getCameraForPosition(position: input.device.position == .back ? .front : .back) {
                do {
                    let maxFps = configureForMaxFps(device: newCam)
                    let newInput:AVCaptureDeviceInput = try AVCaptureDeviceInput(device: newCam)
                    mCaptureDevice = newCam
                    cameraSession.addInput(newInput)
                    cameraSession.commitConfiguration()
                    mDelegate.onCameraPrepared(fps: Float(maxFps))
                } catch let e as NSError {
                    Crashlytics.sharedInstance().recordError(e)
                }
            }
        }
    }
    
    func getCameraForPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        return (AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]).first(where: {$0.position == position})
    }
    
    func getCurrentCaptureHeight() -> CGFloat {
        if (mCurrentData.count == 0) {
            return 0
        } else {
            return (mCurrentData.first?.size.height)!
        }
    }
    
    func setupSession(_ view: UIView) {
        let maxFps: Float
        if mCaptureDevice == nil {
            mCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        do {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil, queue: nil, using: {
                (errorNotif: Notification!) -> Void in
                // TODO: Ideally this would accurately record stack frame
                Crashlytics.sharedInstance().recordCustomExceptionName("SessionError", reason: errorNotif.description, frameArray: [CLSStackFrame()])
                })
            let input = try AVCaptureDeviceInput(device: mCaptureDevice)
            cameraSession.beginConfiguration()
            try mCaptureDevice?.lockForConfiguration()
            
            if let inputs = cameraSession.inputs as? [AVCaptureDeviceInput] {
                if (inputs.count > 0) {
                    cameraSession.removeInput(inputs[0])
                }
            }
            if (cameraSession.canAddInput(input)) {
                cameraSession.addInput(input)
            }
            
            let dataOut = AVCaptureVideoDataOutput()
            dataOut.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
            dataOut.alwaysDiscardsLateVideoFrames = false
            
            if let outputs = cameraSession.outputs as? [AVCaptureOutput] {
                if (outputs.count > 0) {
                    cameraSession.removeOutput(outputs[0])
                }
            }
            if (cameraSession.canAddOutput(dataOut)) {
                cameraSession.addOutput(dataOut)
            }
            
            // TODO: Add selection of mode (> resolution than 720p for grid capture would be nice, 4k would be incredible)
            
            // MAX POWER
            let curMax: Double
            if let captureDevice = mCaptureDevice {
                 curMax = configureForMaxFps(device: captureDevice)
            } else {
                curMax = 0
            }
            mCaptureDevice?.unlockForConfiguration()
            cameraSession.sessionPreset = AVCaptureSessionPresetHigh
            cameraSession.commitConfiguration()

            dataOut.setSampleBufferDelegate(self, queue: mQueue)
            maxFps = Float(curMax)
            
        } catch let error as NSError {
            maxFps = 0
            Crashlytics.sharedInstance().recordError(error)
        }
        preparePreviewLayer(view)
        mDelegate.onCameraPrepared(fps: maxFps)
    }
    
    // Returns the configured max FPS
    func configureForMaxFps(device: AVCaptureDevice) -> Double {
        var curMax = 0.0
        for format in device.formats {
            let ranges = (format as AnyObject).videoSupportedFrameRateRanges as! [AVFrameRateRange]
            let rates = ranges[0]
            
            if (rates.maxFrameRate > curMax) {
                do {
                    try device.lockForConfiguration()
                    device.activeFormat = format as! AVCaptureDeviceFormat
                    device.activeVideoMinFrameDuration = rates.minFrameDuration
                    device.activeVideoMaxFrameDuration = rates.maxFrameDuration
                    device.unlockForConfiguration()
                } catch let error as NSError {
                    Crashlytics.sharedInstance().recordError(error)
                }
                curMax = rates.maxFrameRate
            }
        }
        return curMax
    }
    
    // Returns new state
    func toggleRecording() -> Bool {
        if (!mIsRecording) {
            if let device = mCaptureDevice {
                do {
                    if device.isFocusModeSupported(.locked) {
                        try device.lockForConfiguration()
                        device.focusMode = AVCaptureFocusMode.locked
                        device.unlockForConfiguration()
                    }
                } catch let error as NSError {
                    Crashlytics.sharedInstance().recordError(error)
                }
            }
            mIsRecording = true
        } else {
            if let device = mCaptureDevice {
                do {
                    if device.isFocusModeSupported(.autoFocus) {
                        try device.lockForConfiguration()
                        device.focusMode = AVCaptureFocusMode.autoFocus
                        device.unlockForConfiguration()
                    }
                } catch let error as NSError {
                    Crashlytics.sharedInstance().recordError(error)
                }
            }
            mIsRecording = false
            if (mCurrentData.count > 0) {
                // Enqueue a finish, wait for frames to process
                mQueue.async(execute: {() in
                    self.finishRecording()
                })
            }
        }
        return mIsRecording
    }
    
    func finishRecording() {
        mIsRecording = false
        // Post this to the main thread; this method is usually called from a dispatch queue,
        // no reason for clients to have to worry about that.
        DispatchQueue.main.async {
            self.mDelegate.onRecordingFinished()
        }
    }
    
    func isRecording() -> Bool {
        return mIsRecording
    }
    
    // Returns new state
    func toggleExposureLock() -> Bool {
        if let device = mCaptureDevice {
            do {
                try device.lockForConfiguration()
                let newState: Bool
                if (device.exposureMode != .locked) {
                    device.exposureMode = .locked
                    newState = true
                } else {
                    device.exposureMode = .continuousAutoExposure
                    newState = false
                }
                device.unlockForConfiguration()
                return newState
            } catch let error as NSError {
                Crashlytics.sharedInstance().recordError(error)
            }
        }
        return false
    }
    
    func clearData() {
        mCurrentData.removeAll()
        mFinalImage = nil
    }
    
    @objc func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        let progress = mCaptureProcessor.getProgress(mCurrentData.count)
        let isDone =  mCaptureProcessor.isDone(mCurrentData.count)
        
        if (progress > 0 && !isDone) {
            DispatchQueue.main.async {
                self.mDelegate.onRecordingProgress(percent: progress)
            }
        } else if (!isDone) {
            DispatchQueue.main.async {
                self.mDelegate.onRecordingProgress(frames: self.mCurrentData.count)
            }
        }
        
        if (mIsRecording && isDone) {
            finishRecording()
        } else if (mIsRecording) {
            let img = mCaptureProcessor.process(sampleBuffer, frameCount: mCurrentData.count)
            mCurrentData.append(img)
        }
    }
    
    fileprivate func preparePreviewLayer(_ view: UIView) {
        let viewBounds = view.bounds
        if let oldLayer = mPreviewLayer {
            oldLayer.removeFromSuperlayer()
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraSession)
        previewLayer?.bounds = CGRect(x: 0, y: 0, width: viewBounds.width, height: viewBounds.height)
        previewLayer?.position = CGPoint(x: viewBounds.midX, y: viewBounds.midY)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.insertSublayer(previewLayer!, at: 0)
        if let preview = previewLayer {
            mPreviewLayer = preview
        }
    }
}

protocol CameraEventDelegate {
    func onRecordingProgress(percent: Float)
    func onRecordingProgress(frames: Int)
    func onRecordingFinished()
    func onCameraPrepared(fps: Float)
}
