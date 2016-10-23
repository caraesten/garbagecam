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
    
    func setupSession(_ view: UIView) {
        if mCaptureDevice == nil {
            mCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        do {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil, queue: nil, using: {
                (errorNotif: Notification!) -> Void in
                NSLog("NOTIF:%@", errorNotif.description)
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
            var curMax = 0.0
            if let device = mCaptureDevice {
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
                            NSLog("Issue w/ frame rates: %@", error.localizedDescription)
                        }
                        curMax = rates.maxFrameRate
                    }
                }
            }
            
            try mCaptureDevice?.unlockForConfiguration()
            cameraSession.commitConfiguration()
            
            dataOut.setSampleBufferDelegate(self, queue: mQueue)
            
            
        } catch let error as NSError {
            NSLog("ERROR: %@", error.localizedDescription)
        }
        preparePreviewLayer(view)
    }
    
    // Returns new state
    func toggleRecording() -> Bool {
        if (!mIsRecording) {
            if let device = mCaptureDevice {
                do {
                    try device.lockForConfiguration()
                    device.focusMode = AVCaptureFocusMode.locked
                    device.unlockForConfiguration()
                } catch let e as NSError {
                    NSLog("Couldn't configure focus: %@", e.localizedDescription)
                }
            }
            mIsRecording = true
        } else {
            if let device = mCaptureDevice {
                do {
                    try device.lockForConfiguration()
                    device.focusMode = AVCaptureFocusMode.autoFocus
                    device.unlockForConfiguration()
                } catch let e as NSError {
                    NSLog("Couldn't configure focus: %@", e.localizedDescription)
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
        mDelegate.onRecordingFinished()
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
            } catch let e as NSError {
                NSLog("Couldn't lock exposure: %@", e.localizedDescription)
            }
        }
        return false
    }
    
    func clearData() {
        mCurrentData.removeAll()
        mFinalImage = nil
    }
    
    @objc func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        let isDone =  mCaptureProcessor.isDone(mCurrentData.count)
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
    func onRecordingFinished()
}
