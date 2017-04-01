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
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel
        let pickerLabel = view as? UILabel
        if let aLabel = pickerLabel {
            label = aLabel
        } else {
            label = UILabel()
        }
        label.font = UIFont(name: "Nexa Light", size: 16)
        label.text = mOptions[row].1
        label.textAlignment = .right
        label.textColor = .white
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return mOptions[row].1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        mDelegate?.updatedSetting(settingId: mSettingId, optionId: mOptions[row].0)
    }
    
    func initializeCell(title: String, settingId: CameraSettings.SettingId, options: [(CameraSettings.OptionId, String)], defaultOption: CameraSettings.OptionId, delegate: SettingsUpdatedDelegate) {
        mTitle = title
        mOptions = options
        mSettingId = settingId
        propertyLabel.text = mTitle
        propertyPicker.dataSource = self
        propertyPicker.delegate = self
        mDelegate = delegate
        var row = 0
        for (index, option) in options.enumerated() {
            if (option.0 == defaultOption) {
                row = index
            }
        }
        propertyPicker.selectRow(row, inComponent: 0, animated: false)
    }
}

protocol SettingsUpdatedDelegate {
    func updatedSetting(settingId: CameraSettings.SettingId, optionId: CameraSettings.OptionId)
}
