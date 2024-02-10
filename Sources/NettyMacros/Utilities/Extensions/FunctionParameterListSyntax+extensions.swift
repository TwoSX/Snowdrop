//
//  FunctionParameterListSyntax+extensions.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import SwiftSyntax

struct EnrichedParameter {
    let key: String
    let type: String
    let value: String?
    
    func toString() -> String {
        var result = "\(key): \(type)"
        if let value {
            result += " = \(value)"
        }
        
        return result
    }
}

extension FunctionParameterListSyntax {
    func asEnrichedStringParams(defaultValues: [URLParam]) -> [EnrichedParameter] {
        self.compactMap { param in
            param.asEnrichedStringParam(value: defaultValues.first { $0.key == param.firstName.text || $0.key == param.secondName?.text }?.value)
        }
    }
}

extension FunctionParameterSyntax {
    func asEnrichedStringParam(value: String?) -> EnrichedParameter? {
        var key = firstName.text
        if let secondName {
            key += " \(secondName.text)"
        }
        
        return .init(key: key, type: type.description, value: value?.replacingOccurrences(of: #"\"#, with: ""))
    }
}
