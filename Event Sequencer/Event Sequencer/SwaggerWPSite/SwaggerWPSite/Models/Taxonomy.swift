//
// Taxonomy.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation


open class Taxonomy: JSONEncodable {

    /** All capabilities used by the taxonomy. */
    public var capabilities: Any?
    /** A human-readable description of the taxonomy. */
    public var description: String?
    /** Whether or not the taxonomy should have children. */
    public var hierarchical: Bool?
    /** Human-readable labels for the taxonomy for various contexts. */
    public var labels: Any?
    /** The title for the taxonomy. */
    public var name: String?
    /** An alphanumeric identifier for the taxonomy. */
    public var slug: String?
    /** Whether or not the term cloud should be displayed. */
    public var showCloud: Bool?
    /** Types associated with the taxonomy. */
    public var types: [String]?
    /** REST base route for the taxonomy. */
    public var restBase: String?

    public init() {}

    // MARK: JSONEncodable
    open func encodeToJSON() -> Any {
        var nillableDictionary = [String:Any?]()
        nillableDictionary["capabilities"] = self.capabilities
        nillableDictionary["description"] = self.description
        nillableDictionary["hierarchical"] = self.hierarchical
        nillableDictionary["labels"] = self.labels
        nillableDictionary["name"] = self.name
        nillableDictionary["slug"] = self.slug
        nillableDictionary["show_cloud"] = self.showCloud
        nillableDictionary["types"] = self.types?.encodeToJSON()
        nillableDictionary["rest_base"] = self.restBase

        let dictionary: [String:Any] = APIHelper.rejectNil(nillableDictionary) ?? [:]
        return dictionary
    }
}

