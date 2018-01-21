//
//  UDPClient.swift
//  UDPSockets
//
//  Created by Jeff on 1/21/18.
//  Copyright © 2018 Jeff Small. All rights reserved.
//

import Foundation

class UDPClient {
    /// 1: create a socket
    var socketDescriptor = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)
    var socketAddress: sockaddr_in?

    init() {
        guard socketDescriptor > 0 else {
            print("Initialization of the client failed.")
            socketDescriptor = -1
            return
        }
    }

    deinit {
        print(closeSocket())
    }

    // MARK: Send a message
    /// 3: send a message to the server
    func send(message: String, to ipAddress: String, port: UInt16) -> Int {

        // Assign a socket address for sending messages
        socketAddress = UDPClient.socketAddress(port: port)
        guard var socketAddress = self.socketAddress else {
            print("Could not make the socket address with the given port: \(port)")
            print(strerror(errno))
            return -1
        }

        let connected = ipAddress.withCString{ cs -> Int32 in
            let connectionStatus = inet_pton(AF_INET, cs, &socketAddress.sin_addr)
            if connectionStatus < 0 {
                print("Invalid IP Address: \(ipAddress);\nCould not determine destination.")
                print("Connection Status: \(connectionStatus)\n\(strerror(errno))")
            }
            return connectionStatus
        }

        guard connected > 0 else {
            return -1
        }

        let messageString = Array(message.utf8)
        return withUnsafePointer(to: &socketAddress) { socketAddressPointer -> Int in
            let socket = UnsafeRawPointer(socketAddressPointer)
                .assumingMemoryBound(to: sockaddr.self)

            let sent = sendto(socketDescriptor,
                              messageString,
                              messageString.count,
                              0,
                              socket,
                              socklen_t(socketAddress.sin_len))

            print("Sent \(sent) bytes as \(messageString)")

            if sent < 0 {
                let errmsg = String(cString: strerror(errno))
                print("Send failed: \(errmsg)")
            }

            return sent
        }
    }

    // MARK: Close socket
    func closeSocket() -> Int32 {
        print("Client closing socket")
        return close(socketDescriptor)
    }

    static func socketAddress(port: UInt16) -> sockaddr_in {
        return sockaddr_in(sin_len:    UInt8(MemoryLayout<sockaddr_in>.size),
                           sin_family: sa_family_t(AF_INET),
                           sin_port:   ByteOrder.htons(port),
                           sin_addr:   in_addr(s_addr: 0),
                           sin_zero:   ( 0, 0, 0, 0, 0, 0, 0, 0 )
        )
    }
}
