//
//  TileProcessor.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/16/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class TileProcessor: ImageProcessor {
    let mColumns: Int
    let mRows: Int
    
    init(columns: Int, rows: Int) {
        mColumns = columns
        mRows = rows
    }
    override func process(_ imageSet: [UIImage]) -> UIImage {
        // TODO: Don't hard-code this
        let totalWidth = 720
        let totalHeight = 1280
        let size = CGSize(width: CGFloat(totalWidth), height: CGFloat(totalHeight))
        UIGraphicsBeginImageContext(size)
        for (index, img) in imageSet.enumerated() {
            let imgWidth = totalWidth / mColumns
            let imgHeight = totalHeight / mRows
            let curColumn = (index % mColumns)
            let curRow = mColumns - 1 - index / mColumns
            
            img.draw(at: CGPoint(x: curColumn * imgWidth,y: curRow * imgHeight))
        }
        let finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return finalImage!
    }
}
