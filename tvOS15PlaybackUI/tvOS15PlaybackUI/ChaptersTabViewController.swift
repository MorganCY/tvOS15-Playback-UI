//
//  PlayerViewController.swift
//  tvOS15PlaybackUI
//
//  Created by Zheng-Yuan Yu on 2022/2/28.
//

/*
Modified codes from Apple's sample code: https://developer.apple.com/documentation/avkit/working_with_overlays_and_parental_controls_in_tvos
 */

import UIKit

class ChaptersTabViewController: UIViewController {

	@IBOutlet var stackView: UIStackView?

	override var preferredFocusEnvironments: [UIFocusEnvironment] {
		return stackView?.arrangedSubviews ?? []
	}
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    convenience init() {
        self.init()
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
