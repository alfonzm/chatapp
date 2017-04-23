//
//  PaddedTextField.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/19/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

//	A plain UITextField but with 10 padding

import UIKit

@IBDesignable
class PaddedTextField: UITextField {
	@IBInspectable var insetX: CGFloat = 10
	@IBInspectable var insetY: CGFloat = 10
	
	// Add padding to placeholder
	override func textRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.insetBy(dx: insetX , dy: insetY)
	}
	
	// Add padding to editable text
	override func editingRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.insetBy(dx: insetX , dy: insetY)
	}
	
	@IBInspectable var placeHolderColor: UIColor? {
		get {
			return self.placeHolderColor
		}
		set {
			self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSForegroundColorAttributeName: newValue!])
		}
	}
}
