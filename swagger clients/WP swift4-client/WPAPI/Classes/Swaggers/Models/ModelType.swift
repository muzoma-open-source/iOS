//
// ModelType.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



open class ModelType: Codable {

    /** All capabilities used by the post type. */
    public var capabilities: Any?
    /** A human-readable description of the post type. */
    public var description: String?
    /** Whether or not the post type should have children. */
    public var hierarchical: Bool?
    /** Human-readable labels for the post type for various contexts. */
    public var labels: Any?
    /** The title for the post type. */
    public var name: String?
    /** An alphanumeric identifier for the post type. */
    public var slug: String?
    /** Taxonomies associated with post type. */
    public var taxonomies: [String]?
    /** REST base route for the post type. */
    public var restBase: String?


    
    public init(capabilities: Any?, description: String?, hierarchical: Bool?, labels: Any?, name: String?, slug: String?, taxonomies: [String]?, restBase: String?) {
        self.capabilities = capabilities
        self.description = description
        self.hierarchical = hierarchical
        self.labels = labels
        self.name = name
        self.slug = slug
        self.taxonomies = taxonomies
        self.restBase = restBase
    }
    

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: String.self)

        try container.encodeIfPresent(capabilities, forKey: "capabilities")
        try container.encodeIfPresent(description, forKey: "description")
        try container.encodeIfPresent(hierarchical, forKey: "hierarchical")
        try container.encodeIfPresent(labels, forKey: "labels")
        try container.encodeIfPresent(name, forKey: "name")
        try container.encodeIfPresent(slug, forKey: "slug")
        try container.encodeIfPresent(taxonomies, forKey: "taxonomies")
        try container.encodeIfPresent(restBase, forKey: "rest_base")
    }

    // Decodable protocol methods

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: String.self)

        capabilities = try container.decodeIfPresent(Any.self, forKey: "capabilities")
        description = try container.decodeIfPresent(String.self, forKey: "description")
        hierarchical = try container.decodeIfPresent(Bool.self, forKey: "hierarchical")
        labels = try container.decodeIfPresent(Any.self, forKey: "labels")
        name = try container.decodeIfPresent(String.self, forKey: "name")
        slug = try container.decodeIfPresent(String.self, forKey: "slug")
        taxonomies = try container.decodeIfPresent([String].self, forKey: "taxonomies")
        restBase = try container.decodeIfPresent(String.self, forKey: "rest_base")
    }
}

