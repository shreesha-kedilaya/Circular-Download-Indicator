//
//  SettingsViewController.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate: class {
    func settingsViewController(_ viewController: SettingsViewController, didDismissWithCaptureMode captureMode: CameraCaptureMode)
}

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingsTableView: UITableView!

    var viewModel = SettingsViewModel()
    weak var delegate: SettingsViewControllerDelegate?

    fileprivate let settingsText = ["Photo", "Video"]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"

        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBAction func dismissButtonClicked(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsText.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell") as? SettingsTableViewCell
        cell?.settingsLabel.text = settingsText[(indexPath as NSIndexPath).row]
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let setting = CameraCaptureMode(rawValue: (indexPath as NSIndexPath).row)
        viewModel.currentSetting = setting!

        delegate?.settingsViewController(self, didDismissWithCaptureMode: viewModel.currentSetting)
    }
}
