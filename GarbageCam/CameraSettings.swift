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
    
    func getCurrentSettings() -> [SettingId: OptionId] {
        return ["":""]
    }
    
    func getOptionsForSetting(id: SettingId) -> [(OptionId, String)]? {
        return [("", "")]
    }
    
    func getDefaultOptionForSetting(id: SettingId) -> (OptionId, String)? {
        return ("", "")
    }
    
    func getDefaultSettings() -> [SettingId: OptionId] {
        /* var dictionary = [SettingId: OptionId]()
        for (k, _) in getSettings() {
            let option: OptionId
            if let defaultsOption = UserDefaults.standard.value(forKey: k) as? String {
                option = defaultsOption
            } else {
                option = (getDefaultOptionForSetting(id: k)?.0) ?? ""
            }
            dictionary[k] = option
        }
        return dictionary */
        return getSettings().reduce([SettingId:OptionId]()) { (dict, tuple) in
            var mutableDict = dict
            let k = tuple.0
            let option: OptionId
            if let defaultsOption = UserDefaults.standard.value(forKey: k) as? String {
                option = defaultsOption
            } else {
                option = (getDefaultOptionForSetting(id: k)?.0) ?? ""
            }
            mutableDict[k] = option
            return mutableDict
        }
    }
    
    func saveSettings(settings: [SettingId: OptionId]) {
        for (key, value) in settings {
            UserDefaults.standard.setValue(value, forKey: key)
        }
    }
    
    func makeCamera(settings: [CameraSettings.SettingId: CameraSettings.OptionId]) -> GarbageCamera {
        preconditionFailure("This has to be overriden")
        return NoneCamera()
    }
}
