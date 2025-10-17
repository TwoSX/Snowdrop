//
//  Snowdrop.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public typealias RequestHandler = @Sendable (URLRequest) -> URLRequest
public typealias ResponseHandler = @Sendable (Data, HTTPURLResponse) -> (Data)

public struct Snowdrop: Sendable {
    public static let core = Core()
}

// MARK: Core

public extension Snowdrop {
    struct Core: Sendable {
        fileprivate init() { /* NOP */ }
    }
}
