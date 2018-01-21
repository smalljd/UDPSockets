//
//  UDPServer.swift
//  UDPSockets
//
//  Created by Jeff on 1/21/18.
//  Copyright © 2018 Jeff Small. All rights reserved.
//

import Foundation

class UDPServer {
    /// create a socket
    var socketDescriptor = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)
    var socketAddress: sockaddr_in
    let addressString: String
    let portDescription: Int

    let bufferLength = 4096
    var responseBuffer = [UInt8](repeating: 0, count: 4096)
    var readSource: DispatchSourceRead?

    init(address: String, port: UInt16) {
        portDescription = Int(port)
        addressString = address
        socketAddress = UDPServer.socketAddress(port: port)

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
    /// name the socket/bind
    func bindSocket() -> Int32 {
        /// Bind the socket to the address
        return withUnsafePointer(to: &socketAddress) { socketAddressPointer -> Int32 in
            let socket = UnsafeRawPointer(socketAddressPointer)
                .assumingMemoryBound(to: sockaddr.self)
            return bind(socketDescriptor, socket, socklen_t(MemoryLayout<sockaddr>.size))
        }
    }

    // MARK: Listen for messages
    /// configure the read source
    func startListening(onQueue dispatchQueue: DispatchQueue) {
        print("Listening on: \(addressString):\(portDescription)")
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
        return {
            print("Event handler triggered")
            var socketStorageAddress = sockaddr_storage()
            var socketAddressLength = socklen_t(MemoryLayout<sockaddr_storage>.size)

            let bytesRead = withUnsafeMutablePointer(to: &socketStorageAddress) { storageAddress -> Int in
                storageAddress.withMemoryRebound(to: sockaddr.self, capacity: 1) { reBoundSocketAddress -> Int in
                    guard self.socketDescriptor > 0 else {
                        print("Couldn't read info: : \(String(cString: strerror(errno)))")
                        return -1
                    }

                    return recvfrom(self.socketDescriptor,
                                    &self.responseBuffer,
                                    self.responseBuffer.count,
                                    0,
                                    UnsafeMutablePointer<sockaddr>(reBoundSocketAddress),
                                    &socketAddressLength)
                }
            }

            let dataRead = self.responseBuffer[0 ..< bytesRead]
            print("read \(bytesRead) bytes: \(dataRead)")
            if let dataString = String(bytes: dataRead, encoding: .utf8) {
                print("The message was: \(dataString)")
            }
        }
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
