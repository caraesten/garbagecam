//
//  SettingsCell.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 9/27/16.
//  Copyright © 2016 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit

class DoneCell: UITableViewCell {
    fileprivate var mDelegate: SettingsDoneDelegate? = nil
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setDelegate(delegate: SettingsDoneDelegate) {
        mDelegate = delegate
    }
    
    @IBAction func onDonePressed(_ sender: UIButton) {
        mDelegate?.onDone()
    }
}

protocol SettingsDoneDelegate {
    func onDone()
}
