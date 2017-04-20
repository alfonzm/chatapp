//
//  PaddedTextField.swift
//  LIGChatApp
//
//	A custom text field with padding
//
//  Created by Alfonz Montelibano on 4/19/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

import UIKit

@IBDesignable
class PaddedTextField: UITextField {
	let insetX: CGFloat = 10
	let insetY: CGFloat = 10
	
	// Add padding to placeholder
	override func textRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.insetBy(dx: insetX , dy: insetY)
	}
	
	// Add padding to editable text
	override func editingRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.insetBy(dx: insetX , dy: insetY)
	}
}
