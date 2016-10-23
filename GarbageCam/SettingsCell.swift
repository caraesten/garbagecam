//
//  SettingsCell.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/27/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit

class SettingsCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {
    fileprivate var mTitle: String = ""
    fileprivate var mOptions: [(CameraSettings.OptionId, String)] = []
    fileprivate var mDelegate: SettingsUpdatedDelegate?
    fileprivate var mSettingId: String = ""
    
    public private(set) var selectedOption: String = ""
    
    @IBOutlet public var propertyLabel: UILabel!
    
    @IBOutlet public var propertyPicker: UIPickerView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return mOptions[row].1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedOption = mOptions[row].0
        // TODO: selectedOption is useless now
        mDelegate?.updatedSetting(settingId: mSettingId, optionId: mOptions[row].0)
    }
    
    func initializeCell(title: String, settingId: CameraSettings.SettingId, options: [(CameraSettings.OptionId, String)], delegate: SettingsUpdatedDelegate) {
        mTitle = title
        mOptions = options
        mSettingId = settingId
        propertyLabel.text = mTitle
        propertyPicker.dataSource = self
        propertyPicker.delegate = self
        mDelegate = delegate
    }
}

protocol SettingsUpdatedDelegate {
    func updatedSetting(settingId: CameraSettings.SettingId, optionId: CameraSettings.OptionId)
}
