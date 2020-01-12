//
// UserInfoViewModel.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation


open class UserInfoViewModel: JSONEncodable {

    public var email: String?
    public var hasRegistered: Bool?
    public var emailVerified: Bool?
    public var loginProvider: String?

    public init() {}

    // MARK: JSONEncodable
    open func encodeToJSON() -> Any {
        var nillableDictionary = [String:Any?]()
        nillableDictionary["Email"] = self.email
        nillableDictionary["HasRegistered"] = self.hasRegistered
        nillableDictionary["EmailVerified"] = self.emailVerified
        nillableDictionary["LoginProvider"] = self.loginProvider

        let dictionary: [String:Any] = APIHelper.rejectNil(nillableDictionary) ?? [:]
        return dictionary
    }
}

