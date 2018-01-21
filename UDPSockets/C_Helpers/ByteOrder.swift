//
//  ByteOrder.swift
//  UDPSockets
//
//  Created by Jeff on 1/21/18.
//  Copyright © 2018 Jeff Small. All rights reserved.
//

import Foundation

struct ByteOrder {
    static let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian

    static let htons  = isLittleEndian ? _OSSwapInt16 : { $0 }
    static let htonl  = isLittleEndian ? _OSSwapInt32 : { $0 }
    static let htonll = isLittleEndian ? _OSSwapInt64 : { $0 }
    static let ntohs  = isLittleEndian ? _OSSwapInt16 : { $0 }
    static let ntohl  = isLittleEndian ? _OSSwapInt32 : { $0 }
    static let ntohll = isLittleEndian ? _OSSwapInt64 : { $0 }

    static let INETADDRESS_ANY = in_addr(s_addr: 0)
}
