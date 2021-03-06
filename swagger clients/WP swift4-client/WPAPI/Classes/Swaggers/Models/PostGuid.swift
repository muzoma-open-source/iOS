//
// PostGuid.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation


/** The globally unique identifier for the object. */

open class PostGuid: Codable {

    /** GUID for the object, as it exists in the database. */
    public var raw: String?
    /** GUID for the object, transformed for display. */
    public var rendered: String?


    
    public init(raw: String?, rendered: String?) {
        self.raw = raw
        self.rendered = rendered
    }
    

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: String.self)

        try container.encodeIfPresent(raw, forKey: "raw")
        try container.encodeIfPresent(rendered, forKey: "rendered")
    }

    // Decodable protocol methods

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: String.self)

        raw = try container.decodeIfPresent(String.self, forKey: "raw")
        rendered = try container.decodeIfPresent(String.self, forKey: "rendered")
    }
}

