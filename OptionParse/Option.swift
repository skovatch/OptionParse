//
//  Option.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/4/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

public enum OptionType {
    case Toggle
    case Parameter
}

public enum OptionParseError: ErrorType, Equatable {
    case NoArguments
    case NoFlag
    case MissingParameter(param: String)
}

public func ==(a: OptionParseError, b: OptionParseError) -> Bool {
    switch (a, b) {
    case (.NoFlag, .NoFlag): return true
    case (.NoArguments, .NoArguments): return true
    case (.MissingParameter(let msg1), .MissingParameter(let msg2)): return msg1 == msg2
    default: return false
    }
}


public struct Option {
    
    public typealias OptionHandler = String? -> Void
    
    private let short: String?
    private let long: String?
    private let type: OptionType
    private let handler: OptionHandler
    
    public init?(type: OptionType, short: String? = nil, long: String? = nil, handler: OptionHandler) {
        guard !isNilOrEmpty(short) || !isNilOrEmpty(long) else {
            assert(false, "Must provide at least one specifier for an option")
            return nil
        }
        guard short == nil || short!.characters.count == 1 else {
            assert(false, "Short specifier must be only one character long")
            return nil
        }
        
        self.type = type
        self.short = short
        self.long = long
        self.handler = handler
    }
    
    func processArguments(inout arguments: [String]) throws {
        guard let option = arguments.first else {
            throw OptionParseError.NoArguments
        }
        
        if option.hasPrefix("--") {
            guard let long = long where option == "--\(long)" else {
                return
            }
        } else if option.hasPrefix("-") {
            guard let short = short where option == "-\(short)" else {
                return
            }
        } else {
            throw OptionParseError.NoFlag
        }
        
        
        switch type {
        case .Toggle:
            arguments.removeFirst()
            handler(nil)
        case .Parameter:
            guard arguments.count > 1 else {
                throw OptionParseError.MissingParameter(param: long ?? short!)
            }
            arguments.removeFirst()
            let parameter = arguments.removeFirst()
            handler(parameter)
        }
    }
}