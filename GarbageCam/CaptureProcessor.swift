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
    fileprivate let mCiContext = CIContext(options: [kCIContextPriorityRequestLow: true])
    
    func process(_ sampleBuffer: CMSampleBuffer, frameCount: Int) -> UIImage {
        let buf = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(buf, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let ciImg = CIImage(cvPixelBuffer: buf)
        
        let rotated = ciImg.transformed(by: CGAffineTransform(rotationAngle: -CGFloat(Double.pi) / 2))
        let translated = rotated.transformed(by: CGAffineTransform(translationX: 0, y: -rotated.extent.origin.y))
        let cropped = translated.cropped(
            to: CGRect(
                x: getCaptureOffsetX(frameCount, bufWidth: Int(rotated.extent.width), bufHeight: Int(rotated.extent.height)),
                y: getCaptureOffsetY(frameCount, bufWidth: Int(rotated.extent.width), bufHeight: Int(rotated.extent.height)),
                width: getCaptureWidth(Int(rotated.extent.width)),
                height: getCaptureHeight(Int(rotated.extent.height))
            )
        )
        
        let cgImg = mCiContext.createCGImage(cropped, from: cropped.extent)

        let img = UIImage(cgImage: cgImg!, scale:1, orientation:.up)
        
        CVPixelBufferUnlockBaseAddress(buf, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        return img
    }
    
    func getCaptureWidth(_ bufWidth: Int) -> Int {
        return bufWidth
    }
    
    func getCaptureHeight(_ bufHeight: Int) -> Int {
        return bufHeight
    }
    
    func getCaptureOffsetX(_ frameNumber: Int, bufWidth: Int, bufHeight: Int) -> Int {
        return 0
    }
    
    func getCaptureOffsetY(_ frameNumber: Int, bufWidth: Int, bufHeight: Int) -> Int {
        return 0
    }
    
    // TODO: Add frame skip for more interesting grid capture
    func isDone(_ frameCount: Int) -> Bool {
        // Goes until user stops UNLESS overriden
        return false
    }
    
    func getProgress(_ frameCount: Int) -> Float {
        return 0;
    }
}
