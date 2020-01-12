//
// RemoveLoginBindingModel.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation


open class RemoveLoginBindingModel: JSONEncodable {

    public var loginProvider: String?
    public var providerKey: String?

    public init() {}

    // MARK: JSONEncodable
    open func encodeToJSON() -> Any {
        var nillableDictionary = [String:Any?]()
        nillableDictionary["LoginProvider"] = self.loginProvider
        nillableDictionary["ProviderKey"] = self.providerKey

        let dictionary: [String:Any] = APIHelper.rejectNil(nillableDictionary) ?? [:]
        return dictionary
    }
}

