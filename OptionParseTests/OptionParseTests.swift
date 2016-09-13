//
//  OptionParseTests.swift
//  OptionParseTests
//
//  Created by Steve Marquis on 8/4/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import XCTest
@testable import OptionParse

extension OptionParseError: Equatable {}
public func ==(a: OptionParseError, b: OptionParseError) -> Bool {
    switch (a, b) {
    case (.noOptions, .noOptions): return true
    case (.missingValue(let msg1), .missingValue(let msg2)): return msg1 == msg2
    case (.missingArgument(let msg1), .missingArgument(let msg2)): return msg1 == msg2
    case (.unknownOption(let opt1), .unknownOption(let opt2)): return opt1 == opt2
    case (.unknownArguments(let args1), .unknownArguments(let args2)): return args1 == args2
    default: return false
    }
}


class OptionParseTests: XCTestCase {
    
    func testToggleOptionParse() {
        var parser = OptionParser(name: "test", usage: "")
        let foo = parser.toggle("foobar", shortName: "f", usage: "Pass to foo some bars")

        var arguments: [String] = []
        assertParseError(try parser._parse(arguments), .noOptions)
        XCTAssertFalse(foo.v)
        
        arguments = ["f"]
        assertParseError(try parser._parse(arguments), .unknownArguments(arguments))
        XCTAssertFalse(foo.v)

        arguments = ["-d"]
        assertParseError(try parser._parse(arguments), .unknownOption("-d"))
        XCTAssertFalse(foo.v)

        arguments = ["-f"]
        try! parser._parse(arguments)
        XCTAssertTrue(foo.v)
        foo.v = false

        arguments = ["--foobar"]
        try! parser._parse(arguments)
        XCTAssertTrue(foo.v)
    }
    
    func testParameterOptionParse() {
        var parser = OptionParser(name: "test", usage: "")

        let foo = parser.flag("foobar", shortName: "f", valueName: "some-bars", usage: "Foo these specific bars")

        var arguments: [String] = []
        assertParseError(try parser._parse(arguments), .noOptions)
        
        arguments = ["f"]
        assertParseError(try parser._parse(arguments), .unknownArguments(arguments))

        arguments = ["-d"]
        assertParseError(try parser._parse(arguments), .unknownOption("-d"))

        arguments = ["-f"]
        assertParseError(try parser._parse(arguments), .missingValue("foobar"))

        arguments = ["--foobar"]
        assertParseError(try parser._parse(arguments), .missingValue("foobar"))

        arguments = ["-f", "Param"]
        try! parser._parse(arguments)
        XCTAssertEqual(foo.v!, "Param")

        arguments = ["--foobar", "Param"]
        try! parser._parse(arguments)
        XCTAssertEqual(foo.v!, "Param")

        let remainder = parser.remainder("remain", usage: "stuff")
        arguments = ["--foobar", "Param", "Extra", "stuff"]
        try! parser._parse(arguments)
        XCTAssertEqual(remainder.v, ["Extra", "stuff"])
    }

    
    fileprivate func assertParseError(_ op: (@autoclosure (Void) throws -> Void), _ error: OptionParseError, file: StaticString = #file, line: UInt = #line) {
        XCTAssertThrowsError(try op(), file: file, line: line) { (producedError) in
            if let parseError = producedError as? OptionParseError {
                XCTAssertEqual(parseError, error)
            } else {
                XCTFail("Didn't get a Parse error, instead got \(producedError)")
            }
        }
    }
    
}
