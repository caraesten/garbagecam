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
    let mFrameMappings: [Int]
    
    init(columns: Int, rows: Int, mappings: [Int]) {
        mColumns = columns
        mRows = rows
        mFrameMappings = mappings
    }
    override func process(_ imageSet: [UIImage]) -> UIImage {
        if (imageSet.count == 0) {
            return UIImage()
        }
        let totalWidth = Int((imageSet.first?.size.width)!) * mRows
        let totalHeight = Int((imageSet.first?.size.height)!) * mColumns
        let size = CGSize(width: CGFloat(totalWidth), height: CGFloat(totalHeight))
        UIGraphicsBeginImageContext(size)
        for (index, img) in imageSet.enumerated() {
            let mappedIndex = mFrameMappings[index]
            let imgWidth = totalWidth / mColumns
            let imgHeight = totalHeight / mRows
            let curColumn = (mappedIndex % mColumns)
            let curRow = mColumns - 1 - mappedIndex / mColumns
            
            img.draw(at: CGPoint(x: curColumn * imgWidth,y: curRow * imgHeight))
        }
        let finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return finalImage!
    }
}
