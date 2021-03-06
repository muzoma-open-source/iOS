//
// ExternalLoginViewModel.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



open class ExternalLoginViewModel: Codable {

    public var name: String?
    public var url: String?
    public var state: String?


    
    public init(name: String?, url: String?, state: String?) {
        self.name = name
        self.url = url
        self.state = state
    }
    

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: String.self)

        try container.encodeIfPresent(name, forKey: "Name")
        try container.encodeIfPresent(url, forKey: "Url")
        try container.encodeIfPresent(state, forKey: "State")
    }

    // Decodable protocol methods

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: String.self)

        name = try container.decodeIfPresent(String.self, forKey: "Name")
        url = try container.decodeIfPresent(String.self, forKey: "Url")
        state = try container.decodeIfPresent(String.self, forKey: "State")
    }
}

