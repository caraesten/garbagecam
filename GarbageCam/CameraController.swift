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
import FirebaseCrashlytics

class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let DEFAULT_QUEUE_NAME = "com.estenh.GarbageCameraQueue"
    static let DEFAULT_PROCESS_QUEUE_NAME = "com.estenh.GarbageCameraProcessQueue"
    
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
    
    fileprivate let mCaptureQueue: DispatchQueue
    fileprivate let mProcessQueue: DispatchQueue
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
        let captureDevice = AVCaptureDevice.default(for: .video)
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
        mCaptureQueue = DispatchQueue(label: mQueueName, qos: .userInitiated, attributes: [])
        mProcessQueue = DispatchQueue(label: CameraController.DEFAULT_PROCESS_QUEUE_NAME, qos: .utility)
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
                    // Crashlytics.sharedInstance().recordError(e)
                }
            }
        }
    }
    
    func getCameraForPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return (AVCaptureDevice.devices(for: .video) as! [AVCaptureDevice]).first(where: {$0.position == position})
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
            mCaptureDevice = AVCaptureDevice.default(for: .video)
        }
        let captureDevice = mCaptureDevice!
        cameraSession.beginConfiguration()
        do {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil, queue: nil, using: {
                (errorNotif: Notification!) -> Void in
                NSLog("Error: %@", errorNotif.description)
                // TODO: Ideally this would accurately record stack frame
                let error = NSError(domain: "SessionError", code: -1001)
                Crashlytics.crashlytics().record(error: error)
                })
            let input = try AVCaptureDeviceInput(device: captureDevice)
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
            dataOut.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
            dataOut.alwaysDiscardsLateVideoFrames = true
            
            let outputs = cameraSession.outputs
            if (outputs.count > 0) {
                cameraSession.removeOutput(outputs[0])
            }
        
            if (cameraSession.canAddOutput(dataOut)) {
                cameraSession.addOutput(dataOut)
            }
            
            // TODO: Add selection of mode (> resolution than 720p for grid capture would be nice, 4k would be incredible)
            dataOut.setSampleBufferDelegate(self, queue: mCaptureQueue)
        } catch let error as NSError {
            NSLog("Error: %@", error.description)
            Crashlytics.crashlytics().record(error: error)
        }
        preparePreviewLayer(view)
        // MAX POWER
        let curMax: Double
        if let captureDevice = mCaptureDevice {
             curMax = configureForMaxFps(device: captureDevice)
        } else {
            curMax = 0
        }
        maxFps = Float(curMax)
        cameraSession.commitConfiguration()
        mDelegate.onCameraPrepared(fps: maxFps)
    }
    
    // Returns the configured max FPS
    func configureForMaxFps(device: AVCaptureDevice) -> Double {
        var curMax = 0.0
        var bestFormat = device.formats.first
        for format in device.formats {
            let ranges = format.videoSupportedFrameRateRanges
            let rates = ranges[0]
            
            if (rates.maxFrameRate > curMax) {
                bestFormat = format
                curMax = rates.maxFrameRate
            }
        }
        do {
            if let formatToConfigure = bestFormat {
                try device.lockForConfiguration()
                device.activeFormat = formatToConfigure
                let rates = formatToConfigure.videoSupportedFrameRateRanges[0]
                device.activeVideoMinFrameDuration = rates.minFrameDuration
                device.activeVideoMaxFrameDuration = rates.minFrameDuration
                device.unlockForConfiguration()
            }
        } catch let error as NSError {
            NSLog("Error: %@", error.description)
            Crashlytics.crashlytics().record(error: error)
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
                        device.focusMode = AVCaptureDevice.FocusMode.locked
                        device.unlockForConfiguration()
                    }
                } catch let error as NSError {
                    NSLog("Error: %@", error.description)
                    Crashlytics.crashlytics().record(error: error)
                }
            }
            mIsRecording = true
        } else {
            if let device = mCaptureDevice {
                do {
                    if device.isFocusModeSupported(.autoFocus) {
                        try device.lockForConfiguration()
                        device.focusMode = AVCaptureDevice.FocusMode.autoFocus
                        device.unlockForConfiguration()
                    }
                } catch let error as NSError {
                    NSLog("Error: %@", error.description)
                    Crashlytics.crashlytics().record(error: error)
                }
            }
            mIsRecording = false
            if (mCurrentData.count > 0) {
                // Enqueue a finish, wait for frames to process
                mCaptureQueue.async(execute: {() in
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
                NSLog("Error: %@", error.description)
                Crashlytics.crashlytics().record(error: error)
            }
        }
        return false
    }
    
    func clearData() {
        mCurrentData.removeAll()
        mFinalImage = nil
    }
    
    
    
    @objc func captureOutput(_ output: AVCaptureOutput,
                             didOutput sampleBuffer: CMSampleBuffer,
                             from connection: AVCaptureConnection) {
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
            mProcessQueue.async {
                let img = self.mCaptureProcessor.process(sampleBuffer, frameCount: self.mCurrentData.count)
                self.mCurrentData.append(img)
            }
        }
    }
    
    fileprivate func preparePreviewLayer(_ view: UIView) {
        let viewBounds = view.bounds
        if let oldLayer = mPreviewLayer {
            oldLayer.removeFromSuperlayer()
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraSession)
        previewLayer.bounds = CGRect(x: 0, y: 0, width: viewBounds.width, height: viewBounds.height)
        previewLayer.position = CGPoint(x: viewBounds.midX, y: viewBounds.midY)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        mPreviewLayer = previewLayer
    }
}

protocol CameraEventDelegate {
    func onRecordingProgress(percent: Float)
    func onRecordingProgress(frames: Int)
    func onRecordingFinished()
    func onCameraPrepared(fps: Float)
}
