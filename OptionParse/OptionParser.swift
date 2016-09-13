//
//  OptionParser.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/5/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

public enum OptionParseError: Error {
    case noOptions
    case missingValue(String)
    case missingArgument(String)
    case unknownOption(String)
    case unknownArguments([String])
}

public struct OptionParser {
    
    private let usage: String
    private let name: String
    public init(name: String, usage: String){
        self.name = name
        self.usage = usage
    }

    //MARK: Parsing

    public func parse(args: [String]? = nil, printUsageOnError: Bool = true) throws {
        let arguments = args ?? Array(CommandLine.arguments.dropFirst())
        do {
            try _parse(arguments)
        } catch let error as OptionParseError {
            if printUsageOnError {
                switch error {
                case .noOptions:
                    printUsage()
                case .missingValue(let str):
                    printUsage(withMessage: "Error: Option '\(str)' requires a value")
                case .missingArgument(let str):
                    printUsage(withMessage: "Error: Missing required argument '\(str)'")
                case .unknownOption(let str):
                    printUsage(withMessage: "Error: Unknown option '\(str)'")
                case .unknownArguments(let args):
                    printUsage(withMessage: "Error: Extra arguments: \(args.map{"'\($0)'"}.joined(separator: ", "))")
                }
            }
            throw error
        } catch let error as NSError {
            if printUsageOnError {
                printUsage(withMessage: error.localizedDescription)
            }
            throw error
        }
    }

    func _parse(_ args: [String]? = nil) throws {
        let arguments = args ?? Array(CommandLine.arguments.dropFirst())
        guard arguments.count > 0 else {
            throw OptionParseError.noOptions
        }

        var remaining = try parseTogglesAndFlags(arguments)
        remaining = try parseArguments(remaining)

        if remaining.count > 0 {
            throw OptionParseError.unknownArguments(remaining)
        }
    }

    private enum OptionParseType {
        case name(String)
        case shortName(Character)
        case argument(String)
        
        init(_ str: String) {
            if str.hasPrefix("--") && str.characters.count > 2 {
                let value = str.substring(from: str.characters.index(str.startIndex, offsetBy: 2))
                self = .name(value)
            } else if str.hasPrefix("-") && str.characters.count == 2 {
                self = .shortName(str.characters.last!)
            } else {
                self = .argument(str)
            }
        }
    }

    private var toggles: [String : Toggle] = [:]
    private var flags: [String : Flag] = [:]
    private var shortNameMap: [Character : String] = [:]

    mutating public func flag(_ name: String, shortName: Character? = nil, valueName: String, usage: String) -> OptionValue<String?> {
        guard flags[name] == nil && toggles[name] == nil else {
            fatalError("Duplicate option during setup. This is programmer error")
        }
        let flag = Flag(name: name, shortName: shortName, valueName: valueName, usage: usage)
        flags[name] = flag
        if let shortName = shortName {
            shortNameMap[shortName] = name
        }
        return flag.value
    }

    mutating public func toggle(_ name: String, shortName: Character? = nil, usage: String) -> OptionValue<Bool> {
        guard flags[name] == nil && toggles[name] == nil else {
            fatalError("Duplicate option during setup. This is programmer error")
        }
        let toggle = Toggle(name: name, shortName: shortName, usage: usage)
        toggles[name] = toggle
        if let shortName = shortName {
            shortNameMap[shortName] = name
        }
        return toggle.value
    }

    // Parses toggles and flags, returning any leftover args
    private func parseTogglesAndFlags(_ arguments: [String]) throws -> [String] {
        var remainingArguments: [String] = []
        var iterator = arguments.makeIterator()
        while let argString = iterator.next() {
            let arg = OptionParseType(argString)
            let name: String
            switch arg {
            case .argument(_):
                remainingArguments.append(argString)
                continue
            case .shortName(let val):
                guard let _ = shortNameMap[val] else {
                    throw OptionParseError.unknownOption(argString)
                }
                name = shortNameMap[val]!
            case .name(let val):
                name = val
            }

            if let toggle = toggles[name] {
                toggle.update(value: true)
            } else if let flag = flags[name] {
                guard let value = iterator.next(), case .argument(_) = OptionParseType(value) else {
                    throw OptionParseError.missingValue(flag.name)
                }
                flag.update(value: value)
            } else {
                throw OptionParseError.unknownOption(argString)
            }
        }
        return remainingArguments
    }


    private var requiredArguments: [RequiredArgument] = []
    private var optionalArguments: [OptionalArgument] = []
    private var remainder: RemainderArgument? = nil
    mutating public func required(_ name: String, usage: String) -> OptionValue<String> {
        let arg = RequiredArgument(name: name, usage: usage)
        requiredArguments.append(arg)
        return arg.value
    }

    mutating public func optional(_ name: String, usage: String) -> OptionValue<String?> {
        let arg = OptionalArgument(name: name, usage: usage)
        optionalArguments.append(arg)
        return arg.value
    }

    mutating public func remainder(_ name: String, usage: String) -> OptionValue<[String]> {
        let arg = RemainderArgument(name: name, usage: usage)
        remainder = arg
        return arg.value
    }

    private func parseArguments(_ arguments: [String]) throws -> [String] {
        var remainingArguments = arguments

        for argument in requiredArguments {
            guard let argString = remainingArguments.first else {
                throw OptionParseError.missingArgument(argument.name)
            }
            remainingArguments.removeFirst()
            argument.update(value: argString)
        }

        for argument in optionalArguments {
            guard let argString = remainingArguments.first else {
                break
            }
            remainingArguments.removeFirst()
            argument.update(value: argString)
        }

        if let remainder = remainder {
            remainder.update(value: remainingArguments)
            remainingArguments.removeAll()
        }

        return remainingArguments
    }

    //MARK: Usage messages
    public func printUsage(withMessage msg: String? = nil) {
        if let msg = msg {
            print(msg)
        }
        print(usageMessage)
    }

    private var sampleAndHelpComponents: [(String, String)] {
        var samples: [(String, String)] = []
        samples += toggles.values.map { ($0.sample, $0.helpMessage) }
        samples += flags.values.map { ($0.sample, $0.helpMessage) }
        samples += requiredArguments.map { ($0.sample, $0.helpMessage) }
        samples += optionalArguments.map { ($0.sample, $0.helpMessage) }
        if let remainder = remainder {
            samples.append((remainder.sample, remainder.helpMessage))
        }
        return samples
    }

    private var usageMessage: String {
        // First construct the info line
        var msg = "usage: \(name) "
        let components = sampleAndHelpComponents
        msg += components.map { $0.0 }.joined(separator: " ")
        msg += "\n\n\(usage.terminalWidthLines(withTabDepth: 1))\n\n"

        // Then the detailed messages
        msg += components.map { $0.1 }.joined(separator: "\n")
        return msg
    }
}

extension String {
    // Helper that splits the string into lines of max width 80 characters. Indents each line by 'tabDepth' tabs.
    func terminalWidthLines(withTabDepth tabDepth: Int) -> String {
        var remainingString = self
        var lines: [String] = []
        while remainingString.characters.count > 80 {
            guard let range = remainingString.rangeOfCharacter(from: CharacterSet.whitespaces, options: .backwards, range: remainingString.startIndex..<remainingString.characters.index(remainingString.startIndex, offsetBy: 80)) else {
                lines.append(remainingString)
                remainingString = ""
                break
            }

            lines.append(remainingString.substring(to: range.lowerBound))
            remainingString = remainingString.substring(from: range.upperBound)
        }

        if !remainingString.isEmpty {
            lines.append(remainingString)
        }



        return lines.map { repeatElement("\t", count: tabDepth).joined(separator: "") + $0 }.joined(separator: "\n")
    }
}
