//
//  Transfer_calculatorTests.swift
//  Transfer calculatorTests
//
//  Created by Thomas Brichart on 25/02/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import XCTest


class Transfer_calculatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAverageDicOfArrays() {
        let entryDic: [Int: [Double]] = [1: [1, 2, 3], 2: [1, 2, 3], 3: [1, 2, 3]]
        let resultDic: [Double] = [1, 2, 3]
        
        let testDic = Utils.averageDicOfArrays(entryDic)
        
        XCTAssert(resultDic == testDic)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
