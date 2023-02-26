//
//  AboutViewController.swift
//  GarbageCam
//
//  Created by Esten Hurtle on 3/20/17.
//  Copyright © 2017 Esten Hurtle. All rights reserved.
//

import Foundation
import UIKit
import Social

class AboutViewController: UIViewController {
    @IBAction func twitterClicked(_ sender: UIButton) {
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter){
            let twSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twSheet.setInitialText("@caraesten your app is Garbage")
            self.present(twSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to send a tweet.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func onDonePressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
