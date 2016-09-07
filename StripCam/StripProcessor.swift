//
//  StripProcessor.swift
//  StripCam
//
//  Created by Esten Hurtle on 9/7/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class StripProcessor: ImageProcessor {
    override func process(imageSet: [UIImage]) -> UIImage {
        let size = CGSizeMake(CGFloat(imageSet.count), 1280)
        UIGraphicsBeginImageContext(size)
        for (index, img) in imageSet.enumerate() {
            img.drawAtPoint(CGPoint(x: index,y: 0))
        }
        let finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return finalImage
    }
}