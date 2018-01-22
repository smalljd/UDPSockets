//
//  UDPServer.swift
//  UDPSockets
//
//  Created by Jeff on 1/21/18.
//  Copyright © 2018 Jeff Small. All rights reserved.
//

import Foundation

class UDPServer {
    let addressString: String
    let bufferLength = 4096
    var clientSocketAddress: sockaddr_in?
    let portDescription: Int // Used for display purposes
    var readBuffer = [UInt8](repeating: 0, count: 4096)
    var readSource: DispatchSourceRead?
    var socketDescriptor = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)
    var socketAddress: sockaddr_in

    init(address: String, port: UInt16) {
        portDescription = Int(port)
        addressString = address
        socketAddress = UDPServer.socketAddress(port: port)
        clearResponseBuffer()

        guard socketDescriptor >= 0 else {
            let errmsg = String(cString: strerror(errno))
            print("Error: Server could not create socket. \(errmsg)")
            return
        }

        guard bindSocket() == 0 else {
            print("Server could not bind the socket: \(String(cString: strerror(errno)))")
            return
        }

        startListening(onQueue: DispatchQueue.main)
    }

    deinit {
        closeSocket()
    }

    // MARK: Bind the socket
    func bindSocket() -> Int32 {
        /// Bind the socket to the address
        return withUnsafePointer(to: &socketAddress) { socketAddressPointer -> Int32 in
            let socket = UnsafeRawPointer(socketAddressPointer)
                .assumingMemoryBound(to: sockaddr.self)
            return bind(socketDescriptor, socket, socklen_t(MemoryLayout<sockaddr>.size))
        }
    }

    // MARK: Listen for messages
    func startListening(onQueue dispatchQueue: DispatchQueue) {
        print("Server listening on: \(addressString):\(portDescription)")
        readSource = DispatchSource.makeReadSource(fileDescriptor: socketDescriptor,
                                                   queue: dispatchQueue)

        readSource?.setEventHandler(handler: eventHandler())
        readSource?.setCancelHandler(handler: cancelHandler())

        /// Register the event handler for incoming packets.
        readSource?.resume()
    }

    func cancelHandler() -> DispatchSource.DispatchSourceHandler? {
        return {
            let errmsg = String(cString: strerror(errno))
            print("Cancel handler \(errmsg)")
            self.closeSocket()
        }
    }

    func eventHandler() -> DispatchSource.DispatchSourceHandler? {
        return { [weak self] in
            guard let `self` = self else {
                return
            }

            print("Event handler triggered")
            var socketAddressLength = socklen_t(MemoryLayout<sockaddr>.size)

            if self.clientSocketAddress == nil {
                self.clientSocketAddress = sockaddr_in()
            }

            let bytesRead = withUnsafeMutablePointer(to: &self.clientSocketAddress) { storageAddress -> Int in
                storageAddress.withMemoryRebound(to: sockaddr.self, capacity: 1) { reBoundSocketAddress -> Int in
                    guard self.socketDescriptor > 0 else {
                        print("Couldn't read info: : \(String(cString: strerror(errno)))")
                        return -1
                    }

                    return recvfrom(self.socketDescriptor,
                                    &self.readBuffer,
                                    self.readBuffer.count,
                                    0,
                                    UnsafeMutablePointer<sockaddr>(reBoundSocketAddress),
                                    &socketAddressLength)
                }
            }

            let dataRead = self.readBuffer[0 ..< bytesRead]
            print("read \(bytesRead) bytes: \(dataRead)")
            if let dataString = String(bytes: dataRead, encoding: .utf8) {
                print("The message was: \(dataString)")
                // Reply to client with the same message.
                self.sendMessageToClient(message: dataString)
            }
        }
    }

    func sendMessageToClient(message: String) {
        defer {
            clearResponseBuffer()
        }

        withUnsafePointer(to: &clientSocketAddress) { clientAddressPointer in
            var clientAddress = UnsafeRawPointer(clientAddressPointer).assumingMemoryBound(to: sockaddr.self).pointee
            let replyConfirmation = sendto(self.socketDescriptor,
                   readBuffer,
                   bufferLength,
                   0,
                   &clientAddress,
                   socklen_t(MemoryLayout<sockaddr>.size))

            guard replyConfirmation >= 0 else {
                print("Error sending message to client: \(strerror(errno))")
                return
            }
        }
    }

    func clearResponseBuffer() {
        readBuffer = [UInt8](repeating: 0, count: 4096)
    }

    // MARK: Close the socket
    func closeSocket() {
        print(" server closing socket")
        close(socketDescriptor)
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
