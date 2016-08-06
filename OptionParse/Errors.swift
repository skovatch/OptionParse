//
//  Errors.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/5/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

enum OptionParseError: ErrorType, Equatable {
    case NoArguments
    case MissingParameter(param: String)
    case UnknownFlag(flag: String)
    case UnknownParameters(params: [String])
}

func ==(a: OptionParseError, b: OptionParseError) -> Bool {
    switch (a, b) {
    case (.NoArguments, .NoArguments): return true
    case (.MissingParameter(let msg1), .MissingParameter(let msg2)): return msg1 == msg2
    case (.UnknownFlag(let flag1), .UnknownFlag(let flag2)): return flag1 == flag2
    case (.UnknownParameters(let params1), .UnknownParameters(let params2)): return params1 == params2
    default: return false
    }
}
