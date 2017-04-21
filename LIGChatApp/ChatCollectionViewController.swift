//
//  ChatCollectionViewController.swift
//  LIGChatApp
//
//  Created by Alfonz Montelibano on 4/21/17.
//  Copyright © 2017 alphonsus. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ChatCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate {
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var messageTextView: UITextView!
	@IBOutlet weak var sendButton: UIButton!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!

	let reuseIdentifier = "messageBubbleCell"

	// Firebase stuff
	var messagesRef: FIRDatabaseReference?
	var messagesRefHandle: FIRDatabaseHandle?
	
	// Chat stuff
	var messages = [Message]()
	var senderId: String = ""
	var senderDisplayName: String = ""
	let placeholderText = "Start a new message"
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// setup textview placeholder
		self.messageTextView.delegate = self
		self.setTextViewToPlaceholder()
		
		// create a custom logout button
		let customLogoutButton: UIButton = UIButton(type: .custom)
		customLogoutButton.setTitle("Log out", for: .normal)
		customLogoutButton.layer.backgroundColor = UIColor(hexString: "#535353").cgColor
		customLogoutButton.setTitle("Log out", for: .normal)
		customLogoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
		customLogoutButton.layer.cornerRadius = 8
		customLogoutButton.frame = CGRect(x: 0, y: 0, width: 67, height: 28)
		
		customLogoutButton.addTarget(self, action: #selector(logoutButtonAction), for: .touchUpInside)
		
		let logoutBarButtonItem = UIBarButtonItem(customView: customLogoutButton)
		self.navigationItem.rightBarButtonItem = logoutBarButtonItem
		
		// style the send button
		self.sendButton.layer.cornerRadius = 8
		self.sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
		
		// style the text view
		self.messageTextView.layer.cornerRadius = 5
		
		// Set current Firebase user
		let currentUser = FIRAuth.auth()?.currentUser
		self.senderId = currentUser!.uid
		self.senderDisplayName = currentUser!.email!.replacingOccurrences(of: "@ligchatapp.com", with: "")
		
		// Firebase messages reference
		self.messagesRef = FIRDatabase.database().reference().child("messages")
		
		// load existing messages
		loadMessages()
		
		// observe for new messages
		observeMessages()
		
		// Register collection view cell
		self.collectionView.register(UINib(nibName: "MessageBubbleCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: self.reuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
	}
	
	// MARK: UITextView delegate
	func textViewDidBeginEditing(_ textView: UITextView) {
		if self.messageTextView.text == placeholderText {
			self.messageTextView.text = ""
		}
		
		self.messageTextView.becomeFirstResponder()
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		if self.messageTextView.text == "" {
			self.setTextViewToPlaceholder()
		}
	}
	
	func setTextViewToPlaceholder() {
		self.messageTextView.text = placeholderText
	}
	

	// MARK: UICollectionViewDataSource 
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		// get a reference to our storyboard cell
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MessageBubbleCollectionViewCell
		
		let message = self.messages[indexPath.item]
		
		cell.messageLabel.text = message.text
		cell.senderNameLabel.text = message.senderName
		
		let size = CGSize(width: 200, height: 1000)
		let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
		let estimatedFrame = NSString(string: message.text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)], context: nil)
		
		let labelVerticalPadding: CGFloat = 7
		let labelHorizontalPadding: CGFloat = 10
		let tailWidth: CGFloat = 5
		let bubbleMargin: CGFloat = 5
		
		// Check if message is outgoing or incoming
		var messageLabelXPosition: CGFloat = labelHorizontalPadding
		var messageBubbleXPosition: CGFloat = bubbleMargin
		var messageSenderXPosition: CGFloat = messageBubbleXPosition
		
		if self.senderId == message.senderId {
			cell.messageBubbleView.type = .outgoing
			
			// if outgoing, align the bubble to the right
			messageBubbleXPosition = self.view.frame.width - estimatedFrame.width - (labelHorizontalPadding * 2) - tailWidth - bubbleMargin
			messageSenderXPosition = messageBubbleXPosition
			
			
			cell.senderNameLabel.textAlignment = .right
		} else {
			cell.messageBubbleView.type = .incoming
			
			// add padding to message
			messageLabelXPosition += tailWidth
			
			// add padding to sender name
			messageSenderXPosition += tailWidth
		}
		
		cell.messageLabel.frame = CGRect(x: messageLabelXPosition, y: labelVerticalPadding, width: estimatedFrame.width, height: estimatedFrame.height)
		cell.messageBubbleView.frame = CGRect(x: messageBubbleXPosition, y: 0, width: estimatedFrame.width + (labelHorizontalPadding * 2) + tailWidth, height: estimatedFrame.height + (labelVerticalPadding * 2))
		cell.senderNameLabel.frame = CGRect(x: 10, y: cell.messageBubbleView.frame.maxY + 5, width: self.view.frame.width - 20, height: 14)
		
//		cell.backgroundColor = UIColor.cyan
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
		let messageText = self.messages[indexPath.item].text
		let size = CGSize(width: 200, height: 1000)
		let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
		let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)], context: nil)
		
		return CGSize(width: view.frame.width, height: estimatedFrame.height + 40)
	}
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.messages.count
	}
	
	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
		return UIEdgeInsetsMake(20, 0, 0, 0)
	}
	
	// MARK: IBActions
	@IBAction func sendButtonAction(_ sender: Any) {
		let messageText: String = self.messageTextView.text
		self.addMessage(withString: messageText, senderId: self.senderId, name: self.senderDisplayName)
		
		let itemRef = messagesRef!.childByAutoId()
		let messageItem = [
			"username": self.senderDisplayName,
			"senderId": self.senderId,
			"text": messageText,
			]
		
		itemRef.setValue(messageItem)
		
		finishSendingMessage()
		
		self.messageTextView.text = ""
	}
	
	@IBAction func logoutButtonAction(_ sender: Any) {
		self.navigationItem.rightBarButtonItem?.isEnabled = false
		self.navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGray], for: .normal)
		
		// Show confirm logout prompt
		let confirmLogoutAlert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: UIAlertControllerStyle.alert)
		
		confirmLogoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
			self.navigationItem.rightBarButtonItem?.isEnabled = true
		}))
		
		confirmLogoutAlert.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (action: UIAlertAction!) in
			do {
				try FIRAuth.auth()?.signOut()
				
				let loginNavController = self.storyboard!.instantiateViewController(withIdentifier: "LoginNavController") as! UINavigationController
				
				self.present(loginNavController, animated: true, completion: nil)
			} catch {
				self.navigationItem.rightBarButtonItem?.isEnabled = true
				
				// Logout failed, show alert
				let alertController = UIAlertController(title: "Log out failed", message: "There was a problem logging out of your account. Please try again.", preferredStyle: .alert)
				
				let tryAgainAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
				alertController.addAction(tryAgainAction)
				
				self.present(alertController, animated: true, completion: nil)
			}
		}))
		
		present(confirmLogoutAlert, animated: true, completion: nil)
	}
	
	// MARK: Firebase functionality
	
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
				self.scrollToBottomMessage(true)
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
				
				self.activityIndicator.stopAnimating()
				self.finishSendingMessage()
				self.scrollToBottomMessage()
			}
		})
	}
	
	
	// MARK: Helper/utility functions
	private func finishSendingMessage() {
		self.collectionView.reloadData()
	}
	
	private func scrollToBottomMessage(_ animated: Bool = false) {
		let lastIndex = self.collectionView.numberOfItems(inSection: 0) - 1
		if lastIndex > 0 {
			let lastItemIndexPath = NSIndexPath(item: lastIndex, section: 0)
			self.collectionView.scrollToItem(at: lastItemIndexPath as IndexPath, at: .bottom, animated: animated)
		}
	}
	
	private func addMessage(withString text: String, senderId: String, name: String) {
		let newMessage = Message(text: text, senderId: senderId, senderName: name)
		messages.append(newMessage)
	}
	
	private func addMessage(withMessageDict message: Dictionary<String,AnyObject>) {
		let messageText = message["text"] as! String
		let messageUsername = message["username"] as! String
		let messageSenderId = message["senderId"] as! String
		self.addMessage(withString: messageText, senderId: messageSenderId, name: messageUsername)
	}
}
