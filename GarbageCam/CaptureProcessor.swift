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
import CoreImage

// A capture processor describes which parts of the hardware image buffer to capture
// as a UIImage. By default, captures the whole image.
class CaptureProcessor {
    let ciContext = CIContext(options: [kCIContextPriorityRequestLow: true])
    
    func process(sampleBuffer: CMSampleBuffer) -> UIImage {
        let buf = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(buf, 0)
        
        let width = CVPixelBufferGetWidth(buf)
        let height = CVPixelBufferGetHeight(buf)
        
        let ciImg = CIImage(CVPixelBuffer: buf)
        
        let cropped = ciImg.imageByCroppingToRect(
            CGRect(
                x: getCaptureOffsetX(),
                y: getCaptureOffsetY(),
                width: getCaptureWidth(width),
                height: getCaptureHeight(height)
            )
        )
        
        let cgImg = ciContext.createCGImage(cropped, fromRect: cropped.extent)

        let img = UIImage(CGImage: cgImg, scale:1, orientation:.Right)
        
        CVPixelBufferUnlockBaseAddress(buf, 0)
        
        return img
    }
    
    func getCaptureWidth(bufWidth: Int) -> Int {
        return bufWidth
    }
    
    func getCaptureHeight(bufHeight: Int) -> Int {
        return bufHeight
    }
    
    func getCaptureOffsetX() -> Int {
        return 0
    }
    
    func getCaptureOffsetY() -> Int {
        return 0
    }
}