//
//  Option.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/4/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

public class OptionValue<T> {
    public var value: T
    private init(_ value: T) {
        self.value = value
    }
}

protocol Option {
    associatedtype Value

    var name: String { get }
    var usage: String { get } // Paragraph describing usage
    var descriptor: String { get } // String describing the option, e.g. "--foo, -f <value>"
    var sample: String { get } // String showing usage, e.g., "[--foo | -f <value>]"

    var value: OptionValue<Value> { get }
}

extension Option {
    var helpMessage: String {
        var lines: [String] = []

        lines.append("\t\(descriptor)")
        lines.append(usage.terminalWidthLines(withTabDepth: 2))
        lines.append("")
        return lines.joinWithSeparator("\n")
    }

    func updateValue(val: Value) {
        value.value = val
    }
}

struct Toggle: Option {
    let name: String
    let shortName: Character?
    let usage: String
    let value: OptionValue<Bool> = OptionValue(false)

    init(name: String, shortName: Character? = nil, usage: String) {
        self.name = name
        self.shortName = shortName
        self.usage = usage
    }

    var descriptor: String {
        var line = "--\(name)"
        if let shortName = shortName {
            line += ", -\(shortName)"
        }
        return line
    }

    var sample: String {
        var line = "[--\(name)"
        if let shortName = shortName {
            line += " | -\(shortName)"
        }
        line += "]"
        return line
    }
}

struct Flag: Option {
    let name: String
    let shortName: Character?
    let usage: String
    let valueName: String
    let value: OptionValue<String?> = OptionValue(nil)
    
    init(name: String, shortName: Character? = nil, valueName: String, usage: String) {
        self.name = name
        self.shortName = shortName
        self.usage = usage
        self.valueName = valueName
    }

    var descriptor: String {
        var line = "--\(name)"
        if let shortName = shortName {
            line += ", -\(shortName)"
        }
        line += " <\(valueName)>"

        return line
    }

    var sample: String {
        var line = "[--\(name)"
        if let shortName = shortName {
            line += " | -\(shortName)"
        }
        line += " <\(valueName)>"
        line += "]"

        return line
    }
}

struct OptionalArgument: Option {
    let name: String
    let usage: String
    let value: OptionValue<String?> = OptionValue(nil)

    init(name: String, usage: String) {
        self.name = name
        self.usage = usage
    }

    var descriptor: String {
        return "<\(name)>"
    }

    var sample: String {
        return "[\(descriptor)]"
    }
}

struct RequiredArgument: Option {
    let name: String
    let usage: String
    let value: OptionValue<String> = OptionValue("")

    init(name: String, required: Bool = false, usage: String) {
        self.name = name
        self.usage = usage
    }

    var descriptor: String {
        return "<\(name)>"
    }

    var sample: String {
        return descriptor
    }
}

struct RemainderArgument: Option {
    let name: String
    let usage: String
    let value: OptionValue<[String]> = OptionValue([])

    init(name: String, required: Bool = false, usage: String) {
        self.name = name
        self.usage = usage
    }

    var descriptor: String {
        return "<\(name)>"
    }

    var sample: String {
        return "\(descriptor)..."
    }
}