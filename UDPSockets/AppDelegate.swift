//
//  AppDelegate.swift
//  UDPSockets
//
//  Created by Jeff on 1/21/18.
//  Copyright © 2018 Jeff Small. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var server: UDPServer?
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        server = UDPServer(address: "127.0.0.1", port: 6600)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        server?.closeSocket()
    }


}

