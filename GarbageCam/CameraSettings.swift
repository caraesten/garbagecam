//
//  CameraSettings.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/27/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation

class CameraSettings {
    // ID is a short string to identify the setting, not human readable or localized
    typealias SettingId = String
    typealias OptionId = String
    
    func getSettings() -> [(SettingId, String)] {
        // Override this
        return [("", "")]
    }
    
    func getOptionsForSetting(id: SettingId) -> [(OptionId, String)]? {
        return [("", "")]
    }
    
    func getDefaultOptionForSetting(id: SettingId) -> (OptionId, String)? {
        return ("", "")
    }
    
    func getDefaultSettings() -> [SettingId: OptionId] {
        return ["":""]
    }
    
    func makeCamera(settings: [CameraSettings.SettingId: CameraSettings.OptionId]) -> GarbageCamera {
        preconditionFailure("This has to be overriden")
        return NoneCamera()
    }
}
