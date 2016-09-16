//
//  TileCaptureProcessor.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/16/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation

class TileCaptureProcessor: CaptureProcessor {
    let mRows: Int
    let mColumns: Int
    
    init(columns: Int, rows: Int) {
        mRows = rows
        mColumns = columns
    }
    
    override func getCaptureHeight(_ bufHeight: Int) -> Int {
        return bufHeight / mRows
    }
    
    override func getCaptureWidth(_ bufWidth: Int) -> Int {
        return bufWidth / mColumns
    }
    
    override func getCaptureOffsetX(_ frameNumber: Int, bufWidth: Int, bufHeight: Int) -> Int {
        let imgWidth = getCaptureWidth(bufWidth)
        return imgWidth * frameNumber % bufWidth
    }
    
    override func getCaptureOffsetY(_ frameNumber: Int, bufWidth: Int, bufHeight: Int) -> Int {
        let imgHeight = getCaptureHeight(bufHeight)
        let curRow = frameNumber / mColumns
        return min(curRow * imgHeight, bufHeight - imgHeight)
    }
    
    override func isDone(_ frameCount: Int) -> Bool {
        return frameCount >= mColumns * mRows
    }
}
