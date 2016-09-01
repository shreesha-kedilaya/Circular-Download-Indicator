//
//  HomeViewController.swift
//  FilterCam
//
//  Created by Shreesha on 01/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    private let screenTexts = ["Camera", "Gallery"]
    private lazy var viewModel = HomeViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Filter Cam"
        tableView.separatorStyle = .None
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenTexts.count
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var vc = UIViewController()
        switch indexPath.row {
        case 0:
            vc = storyboard?.instantiateViewControllerWithIdentifier("CameraCaptureViewController") as! CameraCaptureViewController
        case 1:
            vc = storyboard?.instantiateViewControllerWithIdentifier("GaleryCollectionViewController") as! GaleryCollectionViewController
        default: ()
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HomeTableViewCell") as? HomeTableViewCell
        cell?.selectionStyle = .None
        cell?.name.text = screenTexts[indexPath.row]
        return cell!
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
