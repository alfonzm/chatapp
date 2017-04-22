//
//  SpeechBubble.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/21/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

import UIKit

enum SpeechBubbleType {
	case outgoing
	case incoming
}

class SpeechBubbleView: UIView {
	
		lazy var color:UIColor = UIColor(hexString: "#88e306")
//		lazy var color:UIColor = UIColor.clear
	
	var type: SpeechBubbleType = .incoming
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	required convenience init(withColor frame: CGRect, color:UIColor? = .none) {
		self.init(frame: frame)
		
		if let color = color {
			self.color = color
		}
	}
	
	override func draw(_ rect: CGRect) {
		let rounding:CGFloat = 6
		
		let bubbleFrameXPosition: CGFloat = (self.type == .outgoing) ? 0 : 5
		
		// Draw the main frame
		let bubbleFrame = CGRect(x: bubbleFrameXPosition, y: 0, width: rect.width - 5, height: rect.height)
		let bubblePath = UIBezierPath(roundedRect: bubbleFrame, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: rounding, height: rounding))
		
		//Color the bubbleFrame
		color.setStroke()
		color.setFill()
		bubblePath.stroke()
		bubblePath.fill()
		
		let context = UIGraphicsGetCurrentContext()
		context!.beginPath()
		
		//Draw a tail
		if self.type == .outgoing {
			context!.move(to: CGPoint(x: bubbleFrame.maxX, y: bubbleFrame.maxY - 22))
			context!.addLine(to: CGPoint(x: bubbleFrame.maxX + 5, y: bubbleFrame.maxY - 17))
			context!.addLine(to: CGPoint(x: bubbleFrame.maxX, y: bubbleFrame.maxY - 12))
		} else {
			context!.move(to: CGPoint(x: bubbleFrame.minX, y: bubbleFrame.maxY - 22))
			context!.addLine(to: CGPoint(x: bubbleFrame.minX - 5, y: bubbleFrame.maxY - 17))
			context!.addLine(to: CGPoint(x: bubbleFrame.minX, y: bubbleFrame.maxY - 12))
		}
		
		context!.closePath()
		
		//fill the color
		context!.setFillColor(color.cgColor)
		context!.fillPath()
	}
}
