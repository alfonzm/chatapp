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

class ChatCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
	
	@IBOutlet weak var logoutButton: UIBarButtonItem!
	@IBOutlet weak var collectionView: UICollectionView!

	let reuseIdentifier = "messageBubbleCell"

	// Firebase stuff
	var messagesRef: FIRDatabaseReference?
	var messagesRefHandle: FIRDatabaseHandle?
	
	// Chat stuff
	var messages = [Message]()
	var senderId: String = ""
	var senderDisplayName: String?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Set current Firebase user
		let currentUser = FIRAuth.auth()?.currentUser
		self.senderId = currentUser!.uid
		self.senderDisplayName = currentUser!.email
		
		self.messagesRef = FIRDatabase.database().reference().child("messages")
		
		// load existing messages
		loadMessages()
		
		// observe for new messages
		observeMessages()

		// scroll to bottom
//		let item = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
//		let lastItemIndex = IndexPath(item: item, section: 0)
//		collectionView?.scrollToItem(at: lastItemIndex, at: UICollectionViewScrollPosition.top, animated: true)
		
		// Register nibs for collection view
		self.collectionView.register(UINib(nibName: "MessageBubbleCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

	// MARK: UICollectionViewDataSource 
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		// get a reference to our storyboard cell
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MessageBubbleCollectionViewCell
		
		
		let message = self.messages[indexPath.item]
		
		print(message.senderName)
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
		} else {
			cell.messageBubbleView.type = .incoming
			
			// add padding to message
			messageLabelXPosition += tailWidth
			
			// add padding to sender name
			messageSenderXPosition += tailWidth
		}
		
		cell.messageLabel.frame = CGRect(x: messageLabelXPosition, y: labelVerticalPadding, width: estimatedFrame.width, height: estimatedFrame.height)
		cell.messageBubbleView.frame = CGRect(x: messageBubbleXPosition, y: 0, width: estimatedFrame.width + (labelHorizontalPadding * 2) + tailWidth, height: estimatedFrame.height + (labelVerticalPadding * 2))
		cell.senderNameLabel.frame = CGRect(x: messageSenderXPosition, y: cell.messageBubbleView.frame.maxY + 5, width: self.view.frame.width - 10, height: 14)
		
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
	private func finishSendingMessage() {
		self.collectionView.reloadData()
	}
	
	private func showActivityIndicator(){
		let container: UIView = UIView()
		container.frame = self.view.frame
		container.center = self.view.center
		
		//Preparing activity indicator to load
//		self.activityIndicator = UIActivityIndicatorView()
//		self.activityIndicator.hidesWhenStopped = true
//		self.activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//		self.activityIndicator.center = container.center
//		self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
//		
//		container.addSubview(activityIndicator)
//		self.view.addSubview(container)
//		
//		self.activityIndicator.startAnimating()
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
