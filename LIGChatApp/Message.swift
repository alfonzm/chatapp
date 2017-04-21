//
//  Message.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/21/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

import Foundation

class Message {
	var text: String
	var senderId: String
	var senderName: String
	
	init(text: String, senderId: String, senderName: String) {
		self.text = text
		self.senderId = senderId
		self.senderName = senderName
	}
}
