//
//  TileCam.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 10/6/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import GameKit

struct TileCam: GarbageCamera {
    static let ID = 0
    static let TITLE = "ChunkyPixel"
    private let mRows: Int
    private let mColumns: Int
    
    var captureProcessor: CaptureProcessor
    var imageProcessor: ImageProcessor
    var settings: CameraSettings
    var id: Int
    var title: String
    
    init(columns: Int, rows: Int, randomCapture: Bool) {
        mRows = rows
        mColumns = columns
        let frameMappings: [Int]
        if (randomCapture) {
            frameMappings = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: Array(0...(rows * columns))) as! [Int]
        } else {
            frameMappings = Array(0...(rows * columns))
        }
        
        captureProcessor = TileCaptureProcessor(columns: mColumns, rows: mRows, mappings: frameMappings)
        imageProcessor = TileProcessor(columns: mColumns, rows: mRows, mappings: frameMappings)
        settings = TileCamSettings()
        id = TileCam.ID
        title = TileCam.TITLE
    }
    
}
