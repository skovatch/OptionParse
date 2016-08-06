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
    
    func testToggleOptionParse() {
        var handlerRan: Bool = false
        var leftoverVars: [String] = []
        let option = Option(name: "foobar", shortName: "f", usage: "Pass to foo some bars") { val in
            handlerRan = true
        }
        var parser = OptionParser()
        parser.on(option)
        
        let helpMessage = "--foobar, -f\n\n\tPass to foo some bars\n"
        XCTAssertEqual(helpMessage, option.helpMessage(0))
        
        var arguments: [String] = []
        assertParseError(try parser.parse(arguments), .NoArguments)
        
        arguments = ["f"]
        assertParseError(try parser.parse(arguments), .UnknownParameters(params: ["f"]))
        
        parser.leftover { vars in
            leftoverVars = vars
        }
        
        try! parser.parse(arguments)
        XCTAssertEqual(leftoverVars, arguments)
        leftoverVars.removeAll()
        
        arguments = ["-d"]
        assertParseError(try parser.parse(arguments), .UnknownFlag(flag: "-d"))
        XCTAssertFalse(handlerRan)
        XCTAssertTrue(leftoverVars.isEmpty)
        
        arguments = ["-f"]
        try! parser.parse(arguments)
        XCTAssertTrue(handlerRan)
        XCTAssertTrue(leftoverVars.isEmpty)
        
        arguments = ["--foobar"]
        handlerRan = false
        try! parser.parse(arguments)
        XCTAssertTrue(handlerRan)
        XCTAssertTrue(leftoverVars.isEmpty)
    }
    
    func testParameterOptionParse() {
        var passedParam: String? = nil
        var leftoverVars: [String] = []
        let option = Option(name: "foobar", shortName: "f", parameter: "some-bars", usage: "Foo these specific bars") { val in
            passedParam = val
        }
        var parser = OptionParser()
        parser.on(option)
        
        let helpMessage = "--foobar, -f <some-bars>\n\n\tFoo these specific bars\n"
        XCTAssertEqual(helpMessage, option.helpMessage(0))
        
        var arguments: [String] = []
        assertParseError(try parser.parse(arguments), .NoArguments)
        
        arguments = ["f"]
        assertParseError(try parser.parse(arguments), .UnknownParameters(params: ["f"]))
        
        parser.leftover { vars in
            leftoverVars = vars
        }
        
        try! parser.parse(arguments)
        XCTAssertEqual(leftoverVars, arguments)
        leftoverVars.removeAll()
        
        arguments = ["-d"]
        assertParseError(try parser.parse(arguments), .UnknownFlag(flag: "-d"))
        XCTAssertNil(passedParam)
        XCTAssertTrue(leftoverVars.isEmpty)
        
        arguments = ["-f"]
        assertParseError(try parser.parse(arguments), .MissingParameter(param: "some-bars"))
        XCTAssertNil(passedParam)
        XCTAssertTrue(leftoverVars.isEmpty)
        
        arguments = ["--foobar"]
        assertParseError(try parser.parse(arguments), .MissingParameter(param: "some-bars"))
        XCTAssertNil(passedParam)
        XCTAssertTrue(leftoverVars.isEmpty)
        
        arguments = ["-f", "Param"]
        passedParam = nil
        try! parser.parse(arguments)
        XCTAssertEqual(passedParam, "Param")
        XCTAssertTrue(leftoverVars.isEmpty)
        
        arguments = ["--foobar", "Param"]
        passedParam = nil
        try! parser.parse(arguments)
        XCTAssertEqual(passedParam, "Param")
        XCTAssertTrue(leftoverVars.isEmpty)
        
        arguments = ["--foobar", "Param", "Extra", "stuff"]
        passedParam = nil
        try! parser.parse(arguments)
        XCTAssertEqual(passedParam, "Param")
        XCTAssertEqual(leftoverVars, ["Extra", "stuff"])

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
