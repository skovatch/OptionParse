//
//  Option.swift
//  OptionParse
//
//  Created by Steve Marquis on 8/4/16.
//  Copyright © 2016 Steve Marquis. All rights reserved.
//

import Foundation

struct Option {
    typealias OptionHandler = String? -> Void
    
    let name: String
    let shortName: Character?
    let handler: OptionHandler
    let usage: String
    let parameter: String?
    var requiresParameter: Bool { return parameter != nil }
    
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
}