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
    
    func process(sampleBuffer: CMSampleBuffer, frameCount: Int) -> UIImage {
        let buf = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(buf, 0)
        
        let ciImg = CIImage(CVPixelBuffer: buf)
        
        let rotated = ciImg.imageByApplyingTransform(CGAffineTransformMakeRotation(-CGFloat(M_PI) / 2))
        let translated = rotated.imageByApplyingTransform(CGAffineTransformMakeTranslation(0, -rotated.extent.origin.y))
        let cropped = translated.imageByCroppingToRect(
            CGRect(
                x: getCaptureOffsetX(frameCount, bufWidth: Int(rotated.extent.width), bufHeight: Int(rotated.extent.height)),
                y: getCaptureOffsetY(frameCount, bufWidth: Int(rotated.extent.width), bufHeight: Int(rotated.extent.height)),
                width: getCaptureWidth(Int(rotated.extent.width)),
                height: getCaptureHeight(Int(rotated.extent.height))
            )
        )
        
        let cgImg = ciContext.createCGImage(cropped, fromRect: cropped.extent)

        let img = UIImage(CGImage: cgImg, scale:1, orientation:.Up)
        
        CVPixelBufferUnlockBaseAddress(buf, 0)
        
        return img
    }
    
    func getCaptureWidth(bufWidth: Int) -> Int {
        return bufWidth
    }
    
    func getCaptureHeight(bufHeight: Int) -> Int {
        return bufHeight
    }
    
    func getCaptureOffsetX(frameNumber: Int, bufWidth: Int, bufHeight: Int) -> Int {
        return 0
    }
    
    func getCaptureOffsetY(frameNumber: Int, bufWidth: Int, bufHeight: Int) -> Int {
        return 0
    }
    
    // TODO: Add frame skip for more interesting grid capture
    
    func isDone(frameCount: Int) -> Bool {
        // Goes until user stops UNLESS overriden
        return false
    }
}