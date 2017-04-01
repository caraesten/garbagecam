//
//  TileCamSettings.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/27/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation

class TileCamSettings: CameraSettings {
    // TODO: Make these localizable and give constants for IDs
    private let settings = [
        "chunk_size": "Chunk Size",
        "sampling_order": "Sampling Order"]
    

    private let options = [
        "chunk_size": ["small":"Small", "medium": "Medium", "large": "Large"],
        "sampling_order": ["sequential":"Sequential", "random": "Random"]
    ]
    
    private let defaults = [
        "chunk_size": "medium",
        "sampling_order": "sequential"
    ]
    
    private let keySort = { (one: (key: String, value: String), two: (key: String, value: String)) -> Bool in
        one.key > two.key
    }
    
    override func getSettings() -> [(CameraSettings.SettingId, String)] {
        return settings.sorted(by: keySort)
    }
    override func getOptionsForSetting(id: CameraSettings.SettingId) -> [(CameraSettings.OptionId, String)]? {
        return options[id]?.sorted(by: keySort)
    }
    override func getDefaultOptionForSetting(id: CameraSettings.SettingId) -> (CameraSettings.OptionId, String)? {
        if let optId = defaults[id] {
            return (optId, options[id]![optId]!)
        } else {
            return nil
        }
    }
    
    override func makeCamera(settings: [CameraSettings.SettingId : CameraSettings.OptionId]) -> GarbageCamera {
        let columns: Int
        let rows: Int
        let size = settings["chunk_size"] ?? defaults["chunk_size"]
        if (size == "small") {
            columns = 40
            rows = 40
        } else if (size == "medium") {
            columns = 20
            rows = 20
        } else if (size == "large") {
            columns = 10
            rows = 10
        } else {
            columns = 1
            rows = 1
        }
        
        let captureOrder = settings["sampling_order"] ?? defaults["sampling_order"]
        
        let randomSample = captureOrder == "random"
        
        return TileCam(columns: columns, rows: rows, randomCapture: randomSample)
    }
}
