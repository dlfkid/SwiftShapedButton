//
//  MainViewController.swift
//  SwiftShapedButton
//
//  Created by LeonDeng on 2019/4/28.
//  Copyright © 2019 LeonDeng. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Main"
        view.backgroundColor = .black
        setupContent()
    }
    
    func setupContent() {
        let testButton = UIButton(type: .custom)
        testButton.setImage(UIImage(named: "playButton"), for: .normal)
        testButton.frame = CGRect(x: 100, y: 100, width: 70, height: 70)
        testButton.isShapedReact = true
        testButton.addTarget(self, action: #selector(buttonDidTappedAction), for: .touchUpInside)
        view.addSubview(testButton)
    }
    
    @objc private func buttonDidTappedAction() {
        print("Button reacted")
    }
}
