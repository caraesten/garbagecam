//
//  CaptureProcessor.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/7/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia

// A capture processor describes which parts of the hardware image buffer to capture
// as a UIImage. By default, captures the whole image.
class CaptureProcessor {
    func process(sampleBuffer: CMSampleBuffer) -> UIImage {
        let buf = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(buf, 0)
        
        let stride = CVPixelBufferGetBytesPerRow(buf)
        let width = CVPixelBufferGetWidth(buf)
        let height = CVPixelBufferGetHeight(buf)
        let srcBuf = CVPixelBufferGetBaseAddress(buf)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGBitmapContextCreate(srcBuf, getCaptureWidth(width), getCaptureHeight(height), 8, stride, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue);
        
        let quartzImage = CGBitmapContextCreateImage(context)
        
        let img = UIImage(CGImage: quartzImage!, scale:1, orientation:.Right)
        
        CVPixelBufferUnlockBaseAddress(buf, 0)
        
        return img
    }
    
    func getCaptureWidth(bufWidth: Int) -> Int {
        return bufWidth
    }
    
    func getCaptureHeight(bufHeight: Int) -> Int {
        return bufHeight
    }
}