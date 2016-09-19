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
    fileprivate let screenTexts = ["Video", "Gallery"]
    fileprivate lazy var viewModel = HomeViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Filter Cam"
        tableView.separatorStyle = .none
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenTexts.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var vc = UIViewController()
        switch (indexPath as NSIndexPath).row {
        case 0:
            vc = storyboard?.instantiateViewController(withIdentifier: "CameraCaptureViewController") as! CameraCaptureViewController
        case 1:
            vc = storyboard?.instantiateViewController(withIdentifier: "GaleryCollectionViewController") as! GaleryCollectionViewController
        default: ()
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableViewCell") as? HomeTableViewCell
        cell?.selectionStyle = .none
        cell?.name.text = screenTexts[(indexPath as NSIndexPath).row]
        return cell!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
