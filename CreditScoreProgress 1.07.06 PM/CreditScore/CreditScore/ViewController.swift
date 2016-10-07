//
//  ViewController.swift
//  CreditScore
//
//  Created by Shreesha on 26/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var circularProgressView: CreditScoreProgressView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        circularProgressView.addProgressLayer(withAnimation: true)
    }
    
    @IBAction func startAnimation(_ sender: AnyObject) {
        circularProgressView.addProgressLayer(withAnimation: true)
    }
}

