//
//  SnowdropError.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public struct SnowdropError: Error, Sendable {
    public let type: ErrorType
    public let details: SnowdropErrorDetails?
    /// Data returned by the request
    public let data: Data?
    
    public init(type: ErrorType, details: SnowdropErrorDetails? = nil, data: Data? = nil) {
        self.type = type
        self.details = details
        self.data = data
    }
}

public extension SnowdropError {
    enum ErrorType: Sendable {
        case failedToMapResponse, unexpectedResponse, noInternetConnection, unknown
    }
    
    var errorDescription: String? {
        switch type {
        case .failedToMapResponse:
            return "Failed to map response."
            
        case .unexpectedResponse:
            return "Unexpected response."
            
        case .noInternetConnection:
            return "Please check your internet connection."
        
        case .unknown:
            return "Unknown"
        }
    }
}

public struct SnowdropErrorDetails: Sendable {
    public let statusCode: Int
    public let localizedString: String
    public let url: URL?
    public let mimeType: String?
    public let headers: [String: String]?
    /// Original (underlying) error
    public let ogError: (any Error)?
    
    public init(
        statusCode: Int,
        localizedString: String,
        url: URL? = nil,
        mimeType: String? = nil,
        headers: [AnyHashable: Any]? = nil,
        ogError: (any Error)? = nil
    ) {
        self.statusCode = statusCode
        self.localizedString = localizedString
        self.url = url
        self.mimeType = mimeType
        // Convert headers to [String: String] for Sendable conformance
        self.headers = headers?.compactMapValues { value in
            if let stringValue = value as? String {
                return stringValue
            }
            return String(describing: value)
        }.reduce(into: [String: String]()) { result, pair in
            result[String(describing: pair.key)] = pair.value
        }
        self.ogError = ogError
    }
}
