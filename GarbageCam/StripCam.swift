//
//  TileCam.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 10/6/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import GameKit

struct StripCam: GarbageCamera {
    static let ID = 1
    static let TITLE = "STRIP"
    var captureProcessor: CaptureProcessor
    var imageProcessor: ImageProcessor
    var settings: CameraSettings
    var id: Int
    var title: String
    
    init() {
        captureProcessor = StripCaptureProcessor()
        imageProcessor = StripProcessor()
        settings = StripCamSettings()
        id = StripCam.ID
        title = StripCam.TITLE
    }
    
}
