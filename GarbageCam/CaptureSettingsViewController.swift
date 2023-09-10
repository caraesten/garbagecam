//
//  CaptureSettingsViewController.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/27/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit

class CaptureSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsUpdatedDelegate, SettingsDoneDelegate {
    
    var settings: CameraSettings? = nil {
        didSet {
            mSelectedSettings = settings?.getDefaultSettings()
        }
    }
    
    var delegate: CaptureSettingsDelegate? = nil
    
    fileprivate var mSelectedSettings: [CameraSettings.SettingId: CameraSettings.OptionId]? = nil
    
    @IBOutlet fileprivate var mTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blur = UIBlurEffect(style: .dark)
        let visualEffectView = UIVisualEffectView(effect: blur)
        visualEffectView.frame = self.view.bounds

        self.view.insertSubview(visualEffectView, at: 0)
        mTableView.dataSource = self
        mTableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return (settings?.getSettings().count ?? 0) + 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if (indexPath.row < (settings?.getSettings().count) ?? 0) {
            let sCell: SettingsCell
            if let settingsCell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell") as! SettingsCell? {
                sCell = settingsCell
            } else {
                sCell = SettingsCell(style:UITableViewCell.CellStyle.default, reuseIdentifier:"SettingsCell")
            }
            sCell.initializeCell(title: "", settingId: "", options: [], defaultOption: "", delegate: self)
            if let camSettings = settings {
                let allSettings = camSettings.getSettings()
                let setting = allSettings[indexPath.row]
                
                // TODO: make this into a struct, tuple is not great
                let id = setting.0
                let title = setting.1
                
                let options = camSettings.getOptionsForSetting(id: id)!
                let defaultSetting = mSelectedSettings?[id]
                
                sCell.initializeCell(title: title, settingId: id, options: options, defaultOption:defaultSetting ?? "", delegate: self)
            }
            cell = sCell
        } else {
            let dCell: DoneCell
            if let doneCell = tableView.dequeueReusableCell(withIdentifier: "DoneCell") as! DoneCell? {
                dCell = doneCell
            } else {
                dCell = DoneCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "DoneCell")
            }
            dCell.setDelegate(delegate: self)
            cell = dCell
        }
        return cell
    }
    
    func updatedSetting(settingId: CameraSettings.SettingId, optionId: CameraSettings.OptionId) {
        mSelectedSettings?[settingId] = optionId
    }
    
    func onDone() {
        settings?.saveSettings(settings: mSelectedSettings ?? [:])
        delegate?.onSettingsFinished(settingsManager: settings!, settings: mSelectedSettings!)
    }
}

protocol CaptureSettingsDelegate {
    func onSettingsFinished(settingsManager: CameraSettings, settings: [CameraSettings.SettingId: CameraSettings.OptionId])
}
