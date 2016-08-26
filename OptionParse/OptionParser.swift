//
//  OptionParser.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/5/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

public enum OptionParseError: ErrorType {
    case NoOptions
    case MissingValue(String)
    case MissingArgument(String)
    case UnknownOption(String)
    case UnknownArguments([String])
}

public struct OptionParser {
    
    private let usage: String
    public init(usage: String){
        self.usage = usage
    }

    //MARK: Parsing

    public func parse(args: [String]? = nil, printUsageOnError: Bool = true) throws {
        let arguments = args ?? Array(Process.arguments.dropFirst())
        do {
            try _parse(arguments)
        } catch let error as OptionParseError {
            if printUsageOnError {
                switch error {
                case .NoOptions:
                    printUsage()
                case .MissingValue(let str):
                    printUsage(withMessage: "Error: Option '\(str)' requires a value")
                case .MissingArgument(let str):
                    printUsage(withMessage: "Error: Missing required argument '\(str)'")
                case .UnknownOption(let str):
                    printUsage(withMessage: "Error: Unknown option '\(str)'")
                case .UnknownArguments(let args):
                    printUsage(withMessage: "Error: Extra arguments: \(args.map{"'\($0)'"}.joinWithSeparator(", "))")
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

    func _parse(args: [String]? = nil) throws {
        let arguments = args ?? Array(Process.arguments.dropFirst())
        guard arguments.count > 0 else {
            throw OptionParseError.NoOptions
        }

        var remaining = try parseTogglesAndFlags(arguments)
        remaining = try parseArguments(remaining)

        if remaining.count > 0 {
            throw OptionParseError.UnknownArguments(remaining)
        }
    }

    private enum OptionParseType {
        case Name(String)
        case ShortName(Character)
        case Argument(String)
        
        init(_ str: String) {
            if str.hasPrefix("--") && str.characters.count > 2 {
                let value = str.substringFromIndex(str.startIndex.advancedBy(2))
                self = .Name(value)
            } else if str.hasPrefix("-") && str.characters.count == 2 {
                self = .ShortName(str.characters.last!)
            } else {
                self = .Argument(str)
            }
        }
    }

    private var toggles: [String : Toggle] = [:]
    private var flags: [String : Flag] = [:]
    private var shortNameMap: [Character : String] = [:]

    // TODO: error on duplicate toggles/flags
    mutating public func flag(name: String, shortName: Character? = nil, valueName: String, usage: String) -> OptionValue<String?> {
        let flag = Flag(name: name, shortName: shortName, valueName: valueName, usage: usage)
        flags[name] = flag
        if let shortName = shortName {
            shortNameMap[shortName] = name
        }
        return flag.value
    }

    mutating public func toggle(name: String, shortName: Character? = nil, usage: String) -> OptionValue<Bool> {
        let toggle = Toggle(name: name, shortName: shortName, usage: usage)
        toggles[name] = toggle
        if let shortName = shortName {
            shortNameMap[shortName] = name
        }
        return toggle.value
    }

    // Parses toggles and flags, returning any leftover args
    private func parseTogglesAndFlags(arguments: [String]) throws -> [String] {
        var remainingArguments: [String] = []
        var iterator = arguments.generate()
        while let argString = iterator.next() {
            let arg = OptionParseType(argString)
            let name: String
            switch arg {
            case .Argument(_):
                remainingArguments.append(argString)
                continue
            case .ShortName(let val):
                guard let _ = shortNameMap[val] else {
                    throw OptionParseError.UnknownOption(argString)
                }
                name = shortNameMap[val]!
            case .Name(let val):
                name = val
            }

            if let toggle = toggles[name] {
                toggle.updateValue(true)
            } else if let flag = flags[name] {
                guard let value = iterator.next(), case .Argument(_) = OptionParseType(value) else {
                    throw OptionParseError.MissingValue(flag.name)
                }
                flag.updateValue(value)
            } else {
                throw OptionParseError.UnknownOption(argString)
            }
        }
        return remainingArguments
    }


    private var requiredArguments: [RequiredArgument] = []
    private var optionalArguments: [OptionalArgument] = []
    private var remainder: RemainderArgument? = nil
    mutating public func required(name: String, usage: String) -> OptionValue<String> {
        let arg = RequiredArgument(name: name, usage: usage)
        requiredArguments.append(arg)
        return arg.value
    }

    mutating public func optional(name: String, usage: String) -> OptionValue<String?> {
        let arg = OptionalArgument(name: name, usage: usage)
        optionalArguments.append(arg)
        return arg.value
    }

    mutating public func remainder(name: String, usage: String) -> OptionValue<[String]> {
        let arg = RemainderArgument(name: name, usage: usage)
        remainder = arg
        return arg.value
    }

    private func parseArguments(arguments: [String]) throws -> [String] {
        var remainingArguments = arguments

        for argument in requiredArguments {
            guard let argString = remainingArguments.first else {
                throw OptionParseError.MissingArgument(argument.name)
            }
            remainingArguments.removeFirst()
            argument.updateValue(argString)
        }

        for argument in optionalArguments {
            guard let argString = remainingArguments.first else {
                break
            }
            remainingArguments.removeFirst()
            argument.updateValue(argString)
        }

        if let remainder = remainder {
            remainder.updateValue(remainingArguments)
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
        var msg = "usage: OptionParseSample "
        let components = sampleAndHelpComponents
        msg += components.map { $0.0 }.joinWithSeparator(" ")
        msg += "\n\n\t\(usage)\n\n"

        // Then the detailed messages
        msg += components.map { $0.1 }.joinWithSeparator("\n")
        return msg
    }


}