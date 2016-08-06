//
//  OptionParser.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/5/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

struct OptionParser {
    
    typealias LeftoverHandler = [String] -> Void
    
    private var leftoverHandler: LeftoverHandler? = nil
    private var options: [Option] = []
    
    enum ArgumentType {
        case Name(String)
        case ShortName(Character)
        case Parameter(String)
        
        init(string str: String) {
            if str.hasPrefix("--") && str.characters.count > 2 {
                let value = str.substringFromIndex(str.startIndex.advancedBy(2))
                self = .Name(value)
            } else if str.hasPrefix("-") && str.characters.count == 2 {
                self = .ShortName(str.characters.last!)
            } else {
                self = .Parameter(str)
            }
        }
        
        var isFlag: Bool {
            if case .Parameter(_) = self {
                return false
            } else {
                return true
            }
        }
        
        var flagName: String {
            switch self {
            case .Name(let str):
                return "--\(str)"
            case .ShortName(let char):
                return "-\(char)"
            case .Parameter(let param):
                return param
            }
        }
    }
    
    func parse(arguments: [String]) throws {
        guard arguments.count > 0 else {
            throw OptionParseError.NoArguments
        }
        
        var nameMap: [String: Option] = [:]
        var shortNameMap: [Character: Option] = [:]
        for option in options {
            let name = option.name
            nameMap[name] = option
            if let shortName = option.shortName {
                shortNameMap[shortName] = option
            }
        }
        
        var remainingParameters: [String] = []
        var iterator = arguments.map({ ArgumentType(string: $0)}).generate()
        while let arg = iterator.next() {
            if case .Parameter(let parameter) = arg {
                remainingParameters.append(parameter)
                continue
            }
            
            var possibleOption: Option? = nil
            switch arg {
            case .Name(let name):
                possibleOption = nameMap[name]
            case .ShortName(let shortName):
                possibleOption = shortNameMap[shortName]
            default:
                fatalError("This shouldn't be possible")
                break
            }
            
            guard let option = possibleOption else {
                throw OptionParseError.UnknownFlag(flag: arg.flagName)
            }
            
            if option.requiresParameter {
                guard let paramArg = iterator.next(), case .Parameter(let parameter) = paramArg else {
                    throw OptionParseError.MissingParameter(param: option.parameter!)
                }
                
                option.handler(parameter)
            } else {
                option.handler(nil)
            }
        }
        
        if remainingParameters.count > 0 {
            guard let leftoverHandler = leftoverHandler else {
                throw OptionParseError.UnknownParameters(params: remainingParameters)
            }
            leftoverHandler(remainingParameters)
        }
    }
    
    mutating func on(option: Option) {
        options.append(option)
    }
    
    mutating func leftover(handler: LeftoverHandler) {
        leftoverHandler = handler
    }
    
    var usageMessage: String {
        var msg = ""
        for option in options {
            msg += option.helpMessage(0)
            msg += "\n"
        }
        return msg
    }
    
}