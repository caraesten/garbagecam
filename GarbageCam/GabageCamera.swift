//
//  GabageCamera.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 10/6/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation

protocol GarbageCamera {
    var captureProcessor: CaptureProcessor {get}
    var imageProcessor: ImageProcessor {get}
    var settings: CameraSettings {get}
}

class NoneCamera: GarbageCamera {
    init() {
        preconditionFailure("This class should never be initialized")
    }
    var captureProcessor: CaptureProcessor = CaptureProcessor()
    var imageProcessor: ImageProcessor = ImageProcessor()
    var settings: CameraSettings = CameraSettings()
}
