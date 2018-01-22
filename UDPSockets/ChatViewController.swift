//
//  ViewController.swift
//  UDPSockets
//
//  Created by Jeff on 1/21/18.
//  Copyright © 2018 Jeff Small. All rights reserved.
//

import Cocoa

class ChatViewController: NSViewController {

    @IBOutlet weak var hostNameTextField: NSTextField!
    @IBOutlet weak var portNumberTextField: NSTextField!
    @IBOutlet var chatMessagesTextView: NSTextView!
    @IBOutlet weak var newMessageTextField: NSTextField!

    var readSource: DispatchSource?

    let client = UDPClient()

    override func viewDidLoad() {
        super.viewDidLoad()

        client.delegate = self
        loadUserDefaults()
    }

    deinit {
        _ = client.closeSocket()
    }

    func loadUserDefaults() {
        if let host = UserDefaults.standard.string(forKey: UserDefaultsConstants.hostName) {
            hostNameTextField.stringValue = host
        }

        if let port = UserDefaults.standard.string(forKey: UserDefaultsConstants.port) {
            portNumberTextField.stringValue = port
        }
    }

    func saveHostToUserDefaults() {
        UserDefaults.standard.set(hostNameTextField.stringValue, forKey: UserDefaultsConstants.hostName)
    }

    func savePortToUserDefaults() {
        UserDefaults.standard.set(portNumberTextField.stringValue, forKey: UserDefaultsConstants.port)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func send(message: String) {
        let address = hostNameTextField.stringValue
        let port = portNumberTextField.stringValue

        print("Sending message to \(address):\(port)")
        let numberFormatter = NumberFormatter()
        guard let portNumber = numberFormatter.number(from: port) else {
            print("Invalid port number")
            return
        }

        let shortPort = portNumber.uint16Value
        let sentConfirmation = client.send(message: message,
                                           to: address,
                                           port: shortPort)
        if sentConfirmation >= 0 {
            newMessageTextField.stringValue = ""
        }
    }

    @IBAction func didTapSendButton(_ sender: Any) {
        send(message: newMessageTextField.stringValue)
    }
}

extension ChatViewController: NSTextFieldDelegate {
    override func controlTextDidEndEditing(_ obj: Notification) {
        super.controlTextDidEndEditing(obj)

        guard let textField = obj.object as? NSTextField else {
            return
        }

        if textField == hostNameTextField {
            saveHostToUserDefaults()
        } else if textField == portNumberTextField {
            savePortToUserDefaults()
        }
    }
}

extension ChatViewController: UDPClientDelegate {
    func didReceiveMessage(_ message: String) {
        print("Message received on client: \(message)")
        var text = chatMessagesTextView.string + "\n"
        text.append(message)
        chatMessagesTextView.string = text
    }
}

