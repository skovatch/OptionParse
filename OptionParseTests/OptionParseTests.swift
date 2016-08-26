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
    case (.NoOptions, .NoOptions): return true
    case (.MissingValue(let msg1), .MissingValue(let msg2)): return msg1 == msg2
    case (.MissingArgument(let msg1), .MissingArgument(let msg2)): return msg1 == msg2
    case (.UnknownOption(let opt1), .UnknownOption(let opt2)): return opt1 == opt2
    case (.UnknownArguments(let args1), .UnknownArguments(let args2)): return args1 == args2
    default: return false
    }
}


class OptionParseTests: XCTestCase {
    
    func testToggleOptionParse() {
        var parser = OptionParser(usage: "")
        let foo = parser.toggle("foobar", shortName: "f", usage: "Pass to foo some bars")

        var arguments: [String] = []
        assertParseError(try parser._parse(arguments), .NoOptions)
        XCTAssertFalse(foo.value)
        
        arguments = ["f"]
        assertParseError(try parser._parse(arguments), .UnknownArguments(arguments))
        XCTAssertFalse(foo.value)

        arguments = ["-d"]
        assertParseError(try parser._parse(arguments), .UnknownOption("-d"))
        XCTAssertFalse(foo.value)

        arguments = ["-f"]
        try! parser._parse(arguments)
        XCTAssertTrue(foo.value)
        foo.value = false

        arguments = ["--foobar"]
        try! parser._parse(arguments)
        XCTAssertTrue(foo.value)
    }
    
    func testParameterOptionParse() {
        var parser = OptionParser(usage: "")

        let foo = parser.flag("foobar", shortName: "f", valueName: "some-bars", usage: "Foo these specific bars")

        var arguments: [String] = []
        assertParseError(try parser._parse(arguments), .NoOptions)
        
        arguments = ["f"]
        assertParseError(try parser._parse(arguments), .UnknownArguments(arguments))

        arguments = ["-d"]
        assertParseError(try parser._parse(arguments), .UnknownOption("-d"))

        arguments = ["-f"]
        assertParseError(try parser._parse(arguments), .MissingValue("foobar"))

        arguments = ["--foobar"]
        assertParseError(try parser._parse(arguments), .MissingValue("foobar"))

        arguments = ["-f", "Param"]
        try! parser._parse(arguments)
        XCTAssertEqual(foo.value!, "Param")

        arguments = ["--foobar", "Param"]
        try! parser._parse(arguments)
        XCTAssertEqual(foo.value!, "Param")

        let remainder = parser.remainder("remain", usage: "stuff")
        arguments = ["--foobar", "Param", "Extra", "stuff"]
        try! parser._parse(arguments)
        XCTAssertEqual(remainder.value, ["Extra", "stuff"])
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
