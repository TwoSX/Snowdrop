//
//  PinningMode.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public struct PinningMode: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}

	public static let ssl = PinningMode(rawValue: 1 << 0)
	public static let certificate = PinningMode(rawValue: 1 << 1)
}
