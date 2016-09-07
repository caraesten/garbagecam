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
    
    private let mQueue: dispatch_queue_t
    private let mQueueName: String
    private let mProcessor: ImageProcessor
    private let mCaptureProcessor: CaptureProcessor
    private let mDelegate: CameraEventDelegate
    
    private var mIsRecording:Bool = false
    private var mIsExposureLocked:Bool = false
    private var mCurrentData:[UIImage] = [UIImage]()
    private var mFinalImage:UIImage?
    private var mCaptureDevice: AVCaptureDevice?
    
    private lazy var cameraSession: AVCaptureSession = {
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let s = AVCaptureSession()
        return s
    }()
    
    init(processor: ImageProcessor, captureProcessor: CaptureProcessor, delegate: CameraEventDelegate, queueName: String?) {
        if let qn = queueName {
            mQueueName = qn
        } else {
            mQueueName = CameraController.DEFAULT_QUEUE_NAME
        }
        mQueue = dispatch_queue_create(mQueueName, DISPATCH_QUEUE_SERIAL)
        mProcessor = processor
        mCaptureProcessor = captureProcessor
        mDelegate = delegate
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
    
    func setupSession(view: UIView) {
        preparePreviewLayer(view)
        
        mCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            let input = try AVCaptureDeviceInput(device: mCaptureDevice)
            cameraSession.beginConfiguration()
            
            if (cameraSession.canAddInput(input)) {
                cameraSession.addInput(input)
            }
            let dataOut = AVCaptureVideoDataOutput()
            dataOut.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
            dataOut.alwaysDiscardsLateVideoFrames = false
            
            if (cameraSession.canAddOutput(dataOut)) {
                cameraSession.addOutput(dataOut)
            }
            
            // MAX POWER
            var curMax = 0.0
            if let device = mCaptureDevice {
                for format in device.formats {
                    let ranges = format.videoSupportedFrameRateRanges as! [AVFrameRateRange]
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
            
            cameraSession.commitConfiguration()
            
            dataOut.setSampleBufferDelegate(self, queue: mQueue)
            
        } catch let error as NSError {
            NSLog("ERROR: %@", error.localizedDescription)
        }
    }
    
    // Returns new state
    func toggleRecording() -> Bool {
        if (!mIsRecording) {
            if let device = mCaptureDevice {
                do {
                    try device.lockForConfiguration()
                    device.focusMode = AVCaptureFocusMode.Locked
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
                    device.focusMode = AVCaptureFocusMode.AutoFocus
                    device.unlockForConfiguration()
                } catch let e as NSError {
                    NSLog("Couldn't configure focus: %@", e.localizedDescription)
                }
            }
            mIsRecording = false
            if (mCurrentData.count > 0) {
                // Enqueue a finish, wait for frames to process
                dispatch_async(mQueue, {() in
                    self.finishRecording()
                })
            }
        }
        return mIsRecording
    }
    
    func finishRecording() {
        
    }
    
    // Returns new state
    func toggleExposureLock() -> Bool {
        if let device = mCaptureDevice {
            do {
                try device.lockForConfiguration()
                let newState: Bool
                if (device.exposureMode != .Locked) {
                    device.exposureMode = .Locked
                    newState = true
                } else {
                    device.exposureMode = .ContinuousAutoExposure
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
    }
    
    @objc func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        if (mIsRecording) {
            let img = mCaptureProcessor.process(sampleBuffer)
            mCurrentData.append(img)
        }
    }
    
    private func preparePreviewLayer(view: UIView) {
        let viewBounds = view.bounds
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraSession)
        previewLayer.bounds = CGRect(x: 0, y: 0, width: viewBounds.width, height: viewBounds.height)
        previewLayer.position = CGPoint(x: CGRectGetMidX(viewBounds), y: CGRectGetMidY(viewBounds))
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
        view.layer.insertSublayer(previewLayer, atIndex: 0)
    }
}

protocol CameraEventDelegate {
    func onRecordingFinished()
}