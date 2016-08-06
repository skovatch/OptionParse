//
//  Option.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/4/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

enum OptionParseError: ErrorType, Equatable {
    case NoArguments
    case NoFlag
    case MissingParameter(param: String)
}

func ==(a: OptionParseError, b: OptionParseError) -> Bool {
    switch (a, b) {
    case (.NoFlag, .NoFlag): return true
    case (.NoArguments, .NoArguments): return true
    case (.MissingParameter(let msg1), .MissingParameter(let msg2)): return msg1 == msg2
    default: return false
    }
}



struct Option {
    typealias OptionHandler = String? -> Void
    
    private let name: String
    private let shortName: Character?
    private let handler: OptionHandler
    private let usage: String
    private let parameter: String?
    
    init(name: String, shortName: Character? = nil, parameter: String? = nil, usage: String, handler: OptionHandler) {
        self.name = name
        self.shortName = shortName
        self.usage = usage
        self.handler = handler
        self.parameter = parameter
    }
    
    func helpMessage(tabDepth: Int) -> String {
        var lines: [String] = []
        var firstLine = "--\(name)"
        if let shortName = shortName {
            firstLine += ", -\(shortName)"
        }
        
        if let parameter = parameter {
            firstLine += " <\(parameter)>"
        }
        lines.append(firstLine)
        lines.append("")
        lines.append("\t\(usage)")
        lines.append("")
        
        let prefix = Repeat(count: tabDepth, repeatedValue: "\t").joinWithSeparator("")
        return lines.map { line in
            guard line.characters.count > 0 else {
                return line
            }
            return prefix + line
        }.joinWithSeparator("\n")
    }
    
    func processArguments(inout arguments: [String]) throws {
        guard let option = arguments.first else {
            throw OptionParseError.NoArguments
        }
        
        if option.hasPrefix("--") {
            guard option == "--\(name)" else {
                return
            }
        } else if option.hasPrefix("-") {
            guard let shortName = shortName where option == "-\(shortName)" else {
                return
            }
        } else {
            throw OptionParseError.NoFlag
        }
        
        if parameter != nil {
            guard arguments.count > 1 else {
                throw OptionParseError.MissingParameter(param: name)
            }
            arguments.removeFirst()
            let parameter = arguments.removeFirst()
            handler(parameter)
        } else {
            arguments.removeFirst()
            handler(nil)
        }
    }
}