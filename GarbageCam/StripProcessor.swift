//
//  StripProcessor.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/7/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class StripProcessor: ImageProcessor {
    override func process(_ imageSet: [UIImage]) -> UIImage {
        if (imageSet.count == 0) {
            return UIImage()
        }
        let size = CGSize(width: CGFloat(imageSet.count), height: (imageSet.first?.size.height)!)
        UIGraphicsBeginImageContext(size)
        for (index, img) in imageSet.enumerated() {
            img.draw(at: CGPoint(x: index,y: 0))
        }
        let finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return finalImage!
    }
}
