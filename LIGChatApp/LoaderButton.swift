//
//  LoaderButton.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/20/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

//	A UIButton extension that can show/hide a loading activity indicator
//	e.g. button.showLoading() or button.hideLoading()

import UIKit

class LoaderButton: UIButton {
	
	var originalButtonText: String?
	var activityIndicator: UIActivityIndicatorView!
	
	func showLoading() {
		originalButtonText = self.titleLabel?.text
		self.setTitle("", for: UIControlState.normal)
		
		if (activityIndicator == nil) {
			activityIndicator = createActivityIndicator()
		}
		
		showSpinning()
	}
	
	func hideLoading() {
		self.setTitle(originalButtonText, for: UIControlState.normal)
		activityIndicator.stopAnimating()
	}
	
	private func createActivityIndicator() -> UIActivityIndicatorView {
		let activityIndicator = UIActivityIndicatorView()
		activityIndicator.hidesWhenStopped = true
		activityIndicator.color = UIColor.white
		return activityIndicator
	}
	
	private func showSpinning() {
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(activityIndicator)
		centerActivityIndicatorInButton()
		activityIndicator.startAnimating()
	}
	
	private func centerActivityIndicatorInButton() {
		let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
		self.addConstraint(xCenterConstraint)
		
		let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
		self.addConstraint(yCenterConstraint)
	}
}
