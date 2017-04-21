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

	@IBOutlet weak var logoutButton: UIBarButtonItem!

	var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
	
	var messagesRef: FIRDatabaseReference?
	var messagesRefHandle: FIRDatabaseHandle?
	var messages = [JSQMessage]()
	
	var outgoingBubbleImage: JSQMessagesBubbleImage?
	var incomingBubbleImage: JSQMessagesBubbleImage?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
//		self.showActivityIndicator()
		
		// Set current user
		let currentUser = FIRAuth.auth()?.currentUser
		self.senderId = currentUser!.uid
		self.senderDisplayName = currentUser!.email
		
		self.messagesRef = FIRDatabase.database().reference().child("messages")
		
		// remove padding for avatars
		collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
		collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
		
		// customize input toolbar
		self.inputToolbar.contentView.backgroundColor = UIColor.white
		self.inputToolbar.contentView.leftBarButtonItem = nil
		
		let rightBarButtonItem = self.inputToolbar.contentView.rightBarButtonItem!
		rightBarButtonItem.setTitle("send", for: .normal)
		rightBarButtonItem.setTitleColor(UIColor.white, for: .normal)
		rightBarButtonItem.setTitleColor(UIColor.white, for: .disabled)
		rightBarButtonItem.titleLabel!.font = UIFont(name: rightBarButtonItem.titleLabel!.font.fontName, size: 14)
		rightBarButtonItem.backgroundColor = UIColor(hexString: "#666666")
		rightBarButtonItem.layer.cornerRadius = 5
//		rightBarButtonItem.contentEdgeInsets = UIEdgeInsets(top: 44, left: 20, bottom: 0, right: 20)
		rightBarButtonItem.frame.size = CGSize(width: 200, height: rightBarButtonItem.frame.height)
		
		let textView = self.inputToolbar.contentView.textView!
		textView.placeHolder = "Start a new message"
		textView.font = UIFont(name: textView.font!.fontName, size: 14)
//		textView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 0)
		textView.contentOffset = CGPoint(x: 30, y: 30)
		textView.backgroundColor = UIColor(hexString: "#f5f8fa")
		textView.textColor = UIColor(hexString: "#647787")
		textView.layer.borderWidth = 0
		textView.layer.borderColor = UIColor.clear.cgColor
		
		// initialize bubble images
//		self.outgoingCellIdentifier = CustomOutgoingCollectionViewCell.cellReuseIdentifier();
//		self.collectionView.register(CustomOutgoingCollectionViewCell.nib(), forCellWithReuseIdentifier: self.outgoingCellIdentifier)

		let bubbleImageFactory = JSQMessagesBubbleImageFactory()
		let greenBubbleColor = UIColor(hexString: "#88e306")
		self.outgoingBubbleImage = bubbleImageFactory!.outgoingMessagesBubbleImage(with: greenBubbleColor)
		self.incomingBubbleImage = bubbleImageFactory!.incomingMessagesBubbleImage(with: greenBubbleColor)
		
		// load existing messages
		loadMessages()
		
		// observe for new messages
		observeMessages()
    }
	
	// MARK: IBActions
	@IBAction func logoutButtonAction(_ sender: Any) {
		self.logoutButton.isEnabled = false
		
		// Show confirm logout prompt
		let confirmLogoutAlert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: UIAlertControllerStyle.alert)
		
		confirmLogoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
			self.logoutButton.isEnabled = true
		}))
		
		confirmLogoutAlert.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (action: UIAlertAction!) in
			do {
				try FIRAuth.auth()?.signOut()
				
				let loginNavController = self.storyboard!.instantiateViewController(withIdentifier: "LoginNavController") as! UINavigationController
				
				self.present(loginNavController, animated: true, completion: nil)
			} catch {
				self.logoutButton.isEnabled = true
				
				// Logout failed, show alert
				let alertController = UIAlertController(title: "Log out failed", message: "There was a problem logging out of your account. Please try again.", preferredStyle: .alert)
				
				let tryAgainAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
				alertController.addAction(tryAgainAction)
				
				self.present(alertController, animated: true, completion: nil)
			}
		}))
		
		present(confirmLogoutAlert, animated: true, completion: nil)
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
	
//	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//		let cell = collectionView.cellForItem(at: indexPath) as? JSQMessagesCollectionViewCell
//		cell?.cellBottomLabel.text = "HANO"
//		
//		return cell!
//	}

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
		
		self.addMessage(withString: text, senderId: self.senderId, name: self.senderDisplayName)
		
		let itemRef = messagesRef!.childByAutoId()
		let messageItem = [
			"username": self.senderDisplayName,
			"senderId": self.senderId,
			"text": text,
		]
		
		itemRef.setValue(messageItem)
		
		finishSendingMessage()
	}
	
	// Observes new messages added and adds them to the chat thread
	private func observeMessages() {
		self.messagesRefHandle = self.messagesRef?.observe(.childAdded, with: { (snapshot) -> Void in
			if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
				for snap in snapshots {
					if let messageDict = snap.value as? Dictionary<String, AnyObject> {
						self.addMessage(withMessageDict: messageDict)
					}
				}
				self.finishSendingMessage()
			}
		})
	}
	
	// Used to load all messages from the DB for the first time
	private func loadMessages () {
		self.messagesRef?.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
			if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
				for snap in snapshots {
					if let messageDict = snap.value as? Dictionary<String, AnyObject> {
						self.addMessage(withMessageDict: messageDict)
					}
				}
				
//				self.activityIndicator.stopAnimating()
				self.finishSendingMessage()
			}
		})
	}
	
	// MARK: Helper/utility functions
	private func showActivityIndicator(){
		let container: UIView = UIView()
		container.frame = self.view.frame
		container.center = self.view.center
		
		//Preparing activity indicator to load
		self.activityIndicator = UIActivityIndicatorView()
		self.activityIndicator.hidesWhenStopped = true
		self.activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
		self.activityIndicator.center = container.center
		self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
		
		container.addSubview(activityIndicator)
		self.view.addSubview(container)
		
		self.activityIndicator.startAnimating()
	}
	
	private func addMessage(withString text: String, senderId: String, name: String) {
		if let message = JSQMessage(senderId: senderId, displayName: name, text: text) {
			messages.append(message)
		}
	}
	
	private func addMessage(withMessageDict message: Dictionary<String,AnyObject>) {
		let messageText = message["text"] as! String
		let messageUsername = message["username"] as! String
		let messageSenderId = message["senderId"] as! String
		self.addMessage(withString: messageText, senderId: messageSenderId, name: messageUsername)
	}
	
	deinit {
		if let messagesHandle = self.messagesRefHandle {
			messagesRef?.removeObserver(withHandle: messagesHandle)
		}
	}
}

// Extend UIColor with hex string converter
extension UIColor {
	convenience init(hexString: String) {
		let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int = UInt32()
		Scanner(string: hex).scanHexInt32(&int)
		let a, r, g, b: UInt32
		switch hex.characters.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (255, 0, 0, 0)
		}
		self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
	}
}
