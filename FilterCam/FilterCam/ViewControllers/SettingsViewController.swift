//
//  SettingsViewController.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate: class {
    func settingsViewController(viewController: SettingsViewController, didDismissWithCaptureMode captureMode: CameraCaptureMode)
}

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingsTableView: UITableView!

    var viewModel = SettingsViewModel()
    weak var delegate: SettingsViewControllerDelegate?

    private let settingsText = ["Photo", "Video"]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"

        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBAction func dismissButtonClicked(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsText.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingsTableViewCell") as? SettingsTableViewCell
        cell?.settingsLabel.text = settingsText[indexPath.row]
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let setting = CameraCaptureMode(rawValue: indexPath.row)
        viewModel.currentSetting = setting!

        delegate?.settingsViewController(self, didDismissWithCaptureMode: viewModel.currentSetting)
    }
}
