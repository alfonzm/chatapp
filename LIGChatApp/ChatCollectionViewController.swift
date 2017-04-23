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
import GSMessages

class ChatCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate {
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var messageTextView: UITextView!
	@IBOutlet weak var sendButton: UIButton!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	let reuseIdentifier = "messageBubbleCell"

	// Firebase stuff
	var initialDataLoaded = false
	var messagesRef: FIRDatabaseReference?
	var messagesRefHandle: FIRDatabaseHandle?
	
	// Chat stuff
	var messages = [Message]()
	var senderId: String = ""
	var senderDisplayName: String = ""
	let placeholderText = "Start a new message"
	
    override func viewDidLoad() {
		super.viewDidLoad()
		
		// Setup authenticated user, messages, etc
		setupFirebase()
		
		// Register collection view cell
		self.collectionView.register(UINib(nibName: "MessageBubbleCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: self.reuseIdentifier)
		
		// Show signed in notification message
		GSMessage.font = UIFont.boldSystemFont(ofSize: 14)
		self.showMessage("Signed in as \(self.senderDisplayName)", type: .success, options:[
			.textPadding(20.0)
		])
		
		// Create the custom logout button
		setupCustomLogoutButton()
		
		// Add corner radiuses
		self.sendButton.layer.cornerRadius = 5
		self.messageTextView.layer.cornerRadius = 5
		
		// Add placeholder logic for text view
		self.messageTextView.delegate = self
		self.messageTextView.textContainerInset = UIEdgeInsets(top: 5, left: 4, bottom: 5, right: 5)
		self.setTextViewToPlaceholder()
		self.sendButton.disable()
    }
	
	private func setupFirebase() {
		// Set current Firebase user
		let currentUser = FIRAuth.auth()?.currentUser
		self.senderId = currentUser!.uid
		self.senderDisplayName = currentUser!.email!.replacingOccurrences(of: "@ligchatapp.com", with: "")
		
		// Setup messages from Firebase
		self.messagesRef = FIRDatabase.database().reference().child("messages")
		
		observeMessages()
		loadMessages()
	}
	
	private func setupCustomLogoutButton() {
		// create a custom button
		let customLogoutButton: UIButton = LoaderButton(type: .custom)
		
		customLogoutButton.setTitle("Log out", for: .normal)
		customLogoutButton.setTitleColor(UIColor.gray, for: .focused)
		customLogoutButton.setTitleColor(UIColor.gray, for: .disabled)
		customLogoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightSemibold)
		
		customLogoutButton.layer.cornerRadius = 5
		customLogoutButton.layer.backgroundColor = UIColor.chatColor.gray.cgColor
		
		customLogoutButton.frame = CGRect(x: 0, y: 0, width: 67, height: 28)
		
		// add logout action
		customLogoutButton.addTarget(self, action: #selector(logoutButtonAction), for: .touchUpInside)
		
		// reduce right margin of logout button
		let logoutBarButtonItem = UIBarButtonItem(customView: customLogoutButton)
		let negativeSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
		negativeSpace.width = -8
		
		// set the right bar button item
		self.navigationItem.setRightBarButtonItems([negativeSpace, logoutBarButtonItem], animated: false)
	}
	
	// On change orientation, reload and layout the collection view
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.collectionView.reloadData()
	}
	
	// MARK: UITextView delegate
	// Used for manual placeholder functionality for TextView
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
	
	func textViewDidChange(_ textView: UITextView) {
		if self.messageTextView.text == "" {
			self.sendButton.disable()
		} else {
			self.sendButton.enable()
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
		
		cell.setMessage(message, senderId: self.senderId, viewWidth: self.view.frame.width)
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {

		// Get the estimated frame of the message label so we can
		// dynamically set the width and height of the message bubble
		let messageText = self.messages[indexPath.item].text
		let estimatedFrame = ChatCollectionViewController.getEstimatedFrameOfMessageLabel(text: messageText)
		
		return CGSize(width: view.frame.width, height: estimatedFrame.height + (7 * 2) + 40)
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
		
		// Add the message to the Firebase database
		let itemRef = messagesRef!.childByAutoId()
		let messageItem = [
			"username": self.senderDisplayName,
			"senderId": self.senderId,
			"text": messageText,
			]
		
		itemRef.setValue(messageItem)
		
		self.messageTextView.text = ""
		self.sendButton.disable()
	}
	
	@IBAction func logoutButtonAction(_ sender: Any) {
		self.navigationItem.rightBarButtonItem?.isEnabled = false
		
		// Show confirm logout prompt
		let confirmLogoutAlert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to logout?", preferredStyle: UIAlertControllerStyle.alert)
		
		// Cancel logout action
		confirmLogoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
			self.navigationItem.rightBarButtonItem?.isEnabled = true
		}))
		
		// Confirm logout action
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
			
			// check if initial data is loaded, since we want this
			// function to run only for newly added messages
			if !self.initialDataLoaded {
				return
			}
			
			if let messageDict = snapshot.value as? Dictionary<String, AnyObject> {
				self.addMessage(withMessageDict: messageDict)
			}
			self.finishSendingMessage()
			self.scrollToBottomMessage(true)
		})
	}
	
	// Used to load all messages from the DB for the first time
	private func loadMessages () {
		self.messagesRef?.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
			if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
				
				// Add all the messages to the chat
				for snap in snapshots {
					if let messageDict = snap.value as? Dictionary<String, AnyObject> {
						self.addMessage(withMessageDict: messageDict)
					}
				}
				
				self.initialDataLoaded = true
				self.activityIndicator.stopAnimating()
				self.finishSendingMessage()
				self.scrollToBottomMessage()
			}
		})
	}
	
	// MARK: Helper/utility functions
	public static func getEstimatedFrameOfMessageLabel(text: String) -> CGRect {
		let size = CGSize(width: 275, height: 1000)
		let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
		return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: MessageBubbleCollectionViewCell.messageDefaultFont], context: nil)
	}
	
	// Called everytime a new message is added to the thread, to reload the collection view
	private func finishSendingMessage() {
		self.collectionView.reloadData()
	}
	
	// Scrolls the thread to the bottom, called on initial load or everytime a new message is added
	private func scrollToBottomMessage(_ animated: Bool = false) {
		let lastIndex = self.collectionView.numberOfItems(inSection: 0) - 1
		if lastIndex > 0 {
			let lastItemIndexPath = NSIndexPath(item: lastIndex, section: 0)
			self.collectionView.scrollToItem(at: lastItemIndexPath as IndexPath, at: .bottom, animated: animated)
		}
	}
	
	// Add a new message bubble to chat with string
	private func addMessage(withString text: String, senderId: String, name: String) {
		let newMessage = Message(text: text, senderId: senderId, senderName: name)
		messages.append(newMessage)
	}
	
	// Add a new message bubble to chat with a message dictionary
	private func addMessage(withMessageDict message: Dictionary<String,AnyObject>) {
		if let messageText = message["text"] as? String,
			let messageUsername = message["username"] as? String,
			let messageSenderId = message["senderId"] as? String {
			self.addMessage(withString: messageText, senderId: messageSenderId, name: messageUsername)
		}
	}
}
