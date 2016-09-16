//
//  StripCaptureProcessor.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/7/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation

class StripCaptureProcessor: CaptureProcessor {
    
    // For the strip camera, just return 1 width
    override func getCaptureWidth(bufWidth: Int) -> Int {
        return 1
    }
}