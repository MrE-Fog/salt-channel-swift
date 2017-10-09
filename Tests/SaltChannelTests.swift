//  SaltChannelTests.swift
//  SaltChannelTests
//
//  Created by Håkan Olsson on 2017-06-02.

import XCTest
import CocoaLumberjack
import Sodium
import Binson

@testable import SaltChannel

let sodium = Sodium()
let testDataSet = SaltTestData(name: "Basic")

class SaltChannelTests: XCTestCase {
    let sodium = Sodium()
    
    override func setUp() {
        super.setUp()
        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        DDTTYLogger.sharedInstance.colorsEnabled = true
    }
    
    func testM1() {
        let mock = EchoMock(mockdata: testDataSet)
        
        let css = testDataSet.get(.client_sk_sec)
        let csp = testDataSet.get(.client_sk_pub)
        let cep = testDataSet.get(.client_ek_pub)
        let ces = testDataSet.get(.client_ek_sec)
        let ssp = testDataSet.get(.host_sk_pub)
        
        let m1 = testDataSet.get(.m1)

        let channel = SaltChannel(channel: mock, sec: css, pub: csp)
        let m1Hash = try? channel.m1(time: 0, myEncPub: cep)

    }
    
    func testHandshake() {
        let mock = BasicHostMock(mockdata: testDataSet)
        
        let css = testDataSet.get(.client_sk_sec)
        let csp = testDataSet.get(.client_sk_pub)
        let cep = testDataSet.get(.client_ek_pub)
        let ces = testDataSet.get(.client_ek_sec)
        let ssp = testDataSet.get(.host_sk_pub)
        
        let r1 = testDataSet.get(.msg1)
        let r2 = testDataSet.get(.msg2)
        
        mock.start()
        let channel = SaltChannel(channel: mock, sec: css, pub: csp)
        
        /*
        XCTAssertThrowsError(try channel.getRemoteSignPub()) { error in
            XCTAssertEqual(error as? ChannelError, ChannelError.setupNotDone)
        }
         */
        
        do {
            try channel.handshake(clientEncSec: ces, clientEncPub: cep)
            XCTAssertEqual(try channel.getRemoteSignPub(), ssp)
        
            channel.register(callback:
                { data in
                    DDLogInfo("Received Callback R2 for R1")
                    XCTAssertEqual(data, r2)
                }, errorhandler:
                { error in
                    DDLogError("Received error instead of R2 for R1: /(error)")
                    XCTAssert(false)
            })
            
            try channel.write([r1])
            sleep(8)

        } catch {
            print(error)
            XCTAssertTrue(false)
        }
    }
}
