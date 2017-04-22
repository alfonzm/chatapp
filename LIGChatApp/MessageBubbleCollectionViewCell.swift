//
//  MessageBubbleCollectionViewCell.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/21/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

import UIKit

class MessageBubbleCollectionViewCell: UICollectionViewCell {
	
	let messageLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 14)
		label.numberOfLines = 0
		label.textColor = UIColor.white
		label.lineBreakMode = .byWordWrapping
		return label
	}()
	
	let messageBubbleView: SpeechBubbleView = {
		let view = SpeechBubbleView()
		view.backgroundColor = UIColor.clear
		view.layer.cornerRadius = 8
		view.layer.masksToBounds = true
		return view
	}()
	
	let senderNameLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 14)
		label.numberOfLines = 1
		label.textColor = UIColor(hexString: "#445361")
		return label
	}()
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.backgroundColor = UIColor.clear
		self.messageLabel.sizeToFit()
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		self.messageBubbleView.addSubview(messageLabel)
		self.addSubview(messageBubbleView)
		self.addSubview(senderNameLabel)
	}
}