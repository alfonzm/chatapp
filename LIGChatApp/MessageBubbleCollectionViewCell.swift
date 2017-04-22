//
//  MessageBubbleCollectionViewCell.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/21/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

import UIKit

class MessageBubbleCollectionViewCell: UICollectionViewCell {
	
	static var messageDefaultFont: UIFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)

	// UI dimensions for chat bubbles
	let labelVerticalPadding: CGFloat = 7
	let labelHorizontalPadding: CGFloat = 10
	let tailWidth: CGFloat = 5
	let bubbleMargin: CGFloat = 5
	
	let messageLabel: UILabel = {
		let label = UILabel()
		label.font = messageDefaultFont
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
		label.font = messageDefaultFont
		label.numberOfLines = 1
		label.textColor = UIColor.chatColor.textDark
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
	
	public func setMessage(_ message: Message, senderId: String, viewWidth: CGFloat) {
		// set message
		self.messageLabel.text = message.text
		
		// Get the estimated frame of the message label so we can
		// dynamically set the width and height of the message bubble
		let estimatedFrame = ChatCollectionViewController.getEstimatedFrameOfMessageLabel(text: message.text)
		
		var messageLabelXPosition: CGFloat = labelHorizontalPadding
		var messageBubbleXPosition: CGFloat = bubbleMargin
		var messageSenderXPosition: CGFloat = messageBubbleXPosition
		
		// Check if message is outgoing or incoming
		if senderId == message.senderId {
			self.messageBubbleView.type = .outgoing
			self.senderNameLabel.text = "You"
			
			// if outgoing, align right
			messageBubbleXPosition = viewWidth - estimatedFrame.width - (labelHorizontalPadding * 2) - tailWidth - 3
			messageSenderXPosition = messageBubbleXPosition
			
			self.senderNameLabel.textAlignment = .right
		} else {
			self.messageBubbleView.type = .incoming
			self.senderNameLabel.text = message.senderName
			
			// add padding to message
			messageLabelXPosition += tailWidth
			
			// add padding to sender name
			messageSenderXPosition += tailWidth
			
			self.senderNameLabel.textAlignment = .left
		}
		
		self.messageLabel.frame = CGRect(x: messageLabelXPosition, y: labelVerticalPadding, width: estimatedFrame.width, height: estimatedFrame.height)
		self.messageBubbleView.frame = CGRect(x: messageBubbleXPosition, y: 0, width: estimatedFrame.width + (labelHorizontalPadding * 2) + tailWidth, height: estimatedFrame.height + (labelVerticalPadding * 2))
		self.senderNameLabel.frame = CGRect(x: 10, y: self.messageBubbleView.frame.maxY + 4, width: viewWidth - 20, height: 14)
		
		// force redraw frames
		self.messageBubbleView.setNeedsDisplay()
		self.senderNameLabel.setNeedsDisplay()
	}
}
