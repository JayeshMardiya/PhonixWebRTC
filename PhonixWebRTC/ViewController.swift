//
//  ViewController.swift
//  SwiftPhoenixClient
//
//  Created by Kyle Oba on 08/25/2015.
//  Copyright (c) 2015 Kyle Oba. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onTapListener(_ sender: Any) {
        let vc: ListenerViewController = ListenerViewController.storyboardInstance.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func onTapPresenter(_ sender: UIButton) {
        let vc: PresenterViewController = PresenterViewController.storyboardInstance.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }

}
