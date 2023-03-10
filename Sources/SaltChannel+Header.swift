//
//  SaltChannel+Header.swift
//  SaltChannel
//
//  Created by Kenneth Pernyer on 2017-10-09.

import Foundation

enum PacketType: Byte {
    case unknown = 0, m1 = 1, m2 = 2, m3 = 3, m4 = 4, app = 5,
    encrypted = 6, a1 = 8, a2 = 9, tt = 10, multi = 11
    
    /**
     ````
     0            Not used
     1            M1
     2            M2
     3            M3
     4            M4
     5            App
     6            Encrypted
     7            Reserved (has been used for Ticket in v2 drafts)
     8            A1
     9            A2
     10           TT (not used in v2 spec)
     11           MultiApp
     12-127       Not used
     ยดยดยดยด
     */
    
    public var hex: String {
        return data.toHexString("0x")
    }
    
    public var data: Data {
        return Data(bytes: [rawValue])
    }
}

protocol Header {
    func createHeader(from packageType: PacketType, first: Bool, last: Bool) -> Data
    func readHeader(from data: Data) -> (type: PacketType, firstBit: Bool, lastBit: Bool)
}

extension SaltChannel: Header {
    static let firstBitMask: UInt8 = 0b00000001
    static let lastBitMask: UInt8  = 0b10000000
    
    func createHeader(from packageType: PacketType, first: Bool = false, last: Bool = false) -> Data {
        let type = packBytes(UInt64(packageType.rawValue), parts: 1)
        
        // TODO: optimize Data
        var bits: UInt8 = first ? SaltChannel.firstBitMask: 0b00000000
        bits = bits | (last ? SaltChannel.lastBitMask: 0b00000000)

        return type + Data([bits])
    }
    
    func readHeader(from data: Data) -> (type: PacketType, firstBit: Bool, lastBit: Bool) {
        let unknown = (type: PacketType.unknown, firstBit: false, lastBit: false)
        
        guard data.count == 2,
            let byte1 = data.first,
            let byte2 = data.last,
            let type = PacketType(rawValue: byte1) else {
            return unknown
        }

        let first = (byte2 & SaltChannel.firstBitMask) != 0
        let last  = (byte2 & SaltChannel.lastBitMask) != 0
        
        return (type, first, last)
    }
}
