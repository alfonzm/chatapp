//
//  ChatViewController.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/19/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import FirebaseDatabase
import FirebaseAuth

class ChatViewController: JSQMessagesViewController {

	var messagesRef: FIRDatabaseReference?
	var messagesRefHandle: FIRDatabaseHandle?
	var messages = [JSQMessage]()
	
	var outgoingBubbleImage: JSQMessagesBubbleImage?
	var incomingBubbleImage: JSQMessagesBubbleImage?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.senderDisplayName = "alfonz"
		
		self.messagesRef = FIRDatabase.database().reference().child("messages")
		
		// remove padding for avatars
		collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
		collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
		
		// initialize bubble images
		let bubbleImageFactory = JSQMessagesBubbleImageFactory()
		self.outgoingBubbleImage = bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
		self.incomingBubbleImage = bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
		
		// load existing messages
		loadMessages()
		
		// observe for new messages
		observeMessages()
    }
	
	// MARK: IBActions
	@IBAction func tapLogoutButton(_ sender: Any) {
		do {
			try FIRAuth.auth()?.signOut()
			print("SIGNED OUT")
		} catch let signOutError as NSError {
			print ("Error signing out: %@", signOutError)
		}
	}
	
	// MARK: Collection view
	override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
		return nil
	}
	
	override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
		return messages[indexPath.item]
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return messages.count
	}

	override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
		let message = messages[indexPath.item]
		if message.senderId == senderId {
			return outgoingBubbleImage!
		} else {
			return incomingBubbleImage!
		}
	}
	
	// MARK: JSQMessages
	override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
		JSQSystemSoundPlayer.jsq_playMessageSentSound()
		addMessage(withId: self.senderId, name: "alfonz", text: text)
		let itemRef = messagesRef!.childByAutoId()
		let messageItem = [
			"senderUsername": "alfonz",
			"text": text
		]
		
		itemRef.setValue(messageItem)
		
		finishSendingMessage()
	}
	
	private func observeMessages() {
		self.messagesRefHandle = self.messagesRef?.observe(.childAdded, with: { (snapshot) -> Void in
			if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
				for snap in snapshots {
					if let messageDict = snap.value as? Dictionary<String, AnyObject> {
						let messageText = messageDict["text"] as! String
						self.addMessage(withId: "1", name: "alfonz", text: messageText)
					}
				}
				self.finishSendingMessage()
			}
		})
	}
	
	private func loadMessages () {
		self.messagesRef?.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
			if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
				for snap in snapshots {
					if let messageDict = snap.value as? Dictionary<String, AnyObject> {
						let messageText = messageDict["text"] as! String
						self.addMessage(withId: "1", name: "alfonz", text: messageText)
					}
				}
				self.finishSendingMessage()
			}
		})
	}
	
	// MARK: Helper/utility functions
	private func addMessage(withId id: String, name: String, text: String) {
		print("adding message \(text)")
		if let message = JSQMessage(senderId: id, displayName: name, text: text) {
			messages.append(message)
		}
	}
	
	deinit {
		if let messagesHandle = self.messagesRefHandle {
			messagesRef?.removeObserver(withHandle: messagesHandle)
		}
	}
}
