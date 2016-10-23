//
//  StripCamSettings.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 10/23/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation

class StripCamSettings: CameraSettings {
    override func makeCamera(settings: [CameraSettings.SettingId: CameraSettings.OptionId]) -> GarbageCamera {
        return StripCam()
    }

}
