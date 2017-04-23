//
//  UIButton+EnableDisable.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/23/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
	func enable() {
		self.isEnabled = true
		self.isUserInteractionEnabled = true
		self.alpha = 1
	}
	
	func disable() {
		self.isEnabled = false
		self.isUserInteractionEnabled = false
		self.alpha = 0.5
	}
}
