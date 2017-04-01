//
//  AppSettings.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 3/23/17.
//  Copyright © 2017 Esten Hurtle. All rights reserved.
//

import Foundation

class AppSettings {
    static let DEBUG_MODE = true
    
    static func isDebug() -> Bool {
        return DEBUG_MODE
    }
}
