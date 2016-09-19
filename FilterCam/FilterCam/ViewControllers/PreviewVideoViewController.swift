//
//  PreviewVideoViewController.swift
//  FilterCam
//
//  Created by Shreesha on 01/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

class PreviewVideoViewController: UIViewController {

    @IBOutlet weak var videoPlayerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var discardButton: UIButton!
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func saveButtonDidClick(_ sender: AnyObject) {

    }

    @IBAction func discardButtonDidClick(_ sender: AnyObject) {

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
