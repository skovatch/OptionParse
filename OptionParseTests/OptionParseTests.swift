//
//  OptionParseTests.swift
//  OptionParseTests
//
//  Created by Steve Marquis on 8/4/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import XCTest
@testable import OptionParse

class OptionParseTests: XCTestCase {
    
    func testOptionInit() {
        
        var option = Option(type: .Toggle, short: nil, long: nil, handler: {_ in })
        XCTAssertNil(option, "Should not have option without flags")
        
        option = Option(type: .Toggle, short: nil, long: "", handler: {_ in })
        XCTAssertNil(option, "Should not have option without flags")
        
        option = Option(type: .Toggle, short: "f", long: nil, handler: {_ in})
        XCTAssertNotNil(option, "Should have option with short specifier")
        
        option = Option(type: .Toggle, short: "f", long: "foobar", handler: {_ in})
        XCTAssertNotNil(option, "Made a valid option")
    }
    
    func testToggleOptionParse() {
        var handlerRan: Bool = false
        let option = Option(type: .Toggle, short: "f", long: "foobar") { val in
            handlerRan = true
        }
        XCTAssertNotNil(option)
        
        var arguments: [String] = []
        assertParseError(try option!.processArguments(&arguments), .NoArguments)
        
        arguments = ["f"]
        assertParseError(try option!.processArguments(&arguments), .NoFlag)
        
        arguments = ["-d"]
        try! option!.processArguments(&arguments)
        XCTAssertEqual(arguments, ["-d"], "No arguments should have been processed")
        XCTAssertFalse(handlerRan)
        
        arguments = ["-f"]
        try! option!.processArguments(&arguments)
        XCTAssertEqual(arguments, [], "Argument should have been processed")
        XCTAssertTrue(handlerRan)
        
        arguments = ["--foobar"]
        handlerRan = false
        try! option!.processArguments(&arguments)
        XCTAssertEqual(arguments, [], "Argument should have been processed")
        XCTAssertTrue(handlerRan)
    }
    
    func testParameterOptionParse() {
        var passedParam: String? = nil
        let option = Option(type: .Parameter, short: "f", long: "foobar") { val in
            passedParam = val
        }
        XCTAssertNotNil(option)
        
        var arguments: [String] = []
        assertParseError(try option!.processArguments(&arguments), .NoArguments)
        
        arguments = ["f"]
        assertParseError(try option!.processArguments(&arguments), .NoFlag)
        
        arguments = ["-d"]
        try! option!.processArguments(&arguments)
        XCTAssertEqual(arguments, ["-d"], "No arguments should have been processed")
        XCTAssertNil(passedParam)
        
        arguments = ["-f"]
        assertParseError(try option!.processArguments(&arguments), .MissingParameter(param: "foobar"))
        XCTAssertEqual(arguments, ["-f"], "Argument should not have been processed")
        XCTAssertNil(passedParam)
        
        arguments = ["--foobar"]
        passedParam = nil
        assertParseError(try option!.processArguments(&arguments), .MissingParameter(param: "foobar"))
        XCTAssertEqual(arguments, ["--foobar"], "Argument should not have been processed")
        XCTAssertNil(passedParam)
        
        arguments = ["-f", "Param"]
        passedParam = nil
        try! option!.processArguments(&arguments)
        XCTAssertEqual(arguments, [], "Argument should have been processed")
        XCTAssertEqual(passedParam, "Param")
        
        arguments = ["--foobar", "Param"]
        passedParam = nil
        try! option!.processArguments(&arguments)
        XCTAssertEqual(arguments, [], "Argument should have been processed")
        XCTAssertEqual(passedParam, "Param")

    }

    
    private func assertParseError(@autoclosure op: (Void throws -> Void), _ error: OptionParseError, file: StaticString = #file, line: UInt = #line) {
        XCTAssertThrowsError(try op(), file: file, line: line) { (producedError) in
            if let parseError = producedError as? OptionParseError {
                XCTAssertEqual(parseError, error)
            } else {
                XCTFail("Didn't get a Parse error, instead got \(producedError)")
            }
        }
    }
    
}
