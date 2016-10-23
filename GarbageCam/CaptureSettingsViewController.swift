//
//  CaptureSettingsViewController.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/27/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit

class CaptureSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsUpdatedDelegate {
    
    var settings: CameraSettings? = nil {
        didSet {
            // TODO: Update this with whatever the user has set otherwise this'll get p annoying
            selectedSettings = settings?.getDefaultSettings()
        }
    }
    
    var delegate: CaptureSettingsDelegate? = nil
    
    var selectedSettings: [CameraSettings.SettingId: CameraSettings.OptionId]? = nil
    
    @IBOutlet var tableView: UITableView!
    
    @IBAction func doneClicked(_ sender: UIButton) {
        delegate?.onSettingsFinished(settingsManager: settings!, settings: selectedSettings!)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blur = UIBlurEffect(style: .dark)
        let visualEffectView = UIVisualEffectView(effect: blur)
        visualEffectView.frame = self.view.bounds

        self.view.insertSubview(visualEffectView, at: 0)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return settings?.getSettings().count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SettingsCell
        if let settingsCell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell") as! SettingsCell? {
            cell = settingsCell
        } else {
            cell = SettingsCell(style:UITableViewCellStyle.default, reuseIdentifier:"SettingsCell")
        }
        cell.initializeCell(title: "", settingId: "", options: [], delegate: self)
        if let camSettings = settings {
            let allSettings = camSettings.getSettings()
            let setting = allSettings[indexPath.row]
            
            // TODO: lol make this into a struct, tuple is not great
            let id = setting.0
            let title = setting.1
            
            let options = camSettings.getOptionsForSetting(id: id)!
            
            cell.initializeCell(title: title, settingId: id, options: options, delegate: self)
        }
        return cell
    }
    
    func updatedSetting(settingId: CameraSettings.SettingId, optionId: CameraSettings.OptionId) {
        selectedSettings?[settingId] = optionId
    }
}

protocol CaptureSettingsDelegate {
    func onSettingsFinished(settingsManager: CameraSettings, settings: [CameraSettings.SettingId: CameraSettings.OptionId])
}
