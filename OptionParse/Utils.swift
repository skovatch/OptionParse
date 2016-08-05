//
//  Utils.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/4/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

public func isNilOrEmpty(str: String?) -> Bool {
    guard let str = str else {
        return true
    }
    
    return str.isEmpty
}