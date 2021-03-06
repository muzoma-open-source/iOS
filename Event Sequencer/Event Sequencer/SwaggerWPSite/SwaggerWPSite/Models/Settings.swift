//
// Settings.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation


open class Settings: JSONEncodable {

    public enum DefaultPingStatus: String { 
        case open = "open"
        case closed = "closed"
    }
    public enum DefaultCommentStatus: String { 
        case open = "open"
        case closed = "closed"
    }
    /** Site title. */
    public var title: String?
    /** Site tagline. */
    public var description: String?
    /** Site URL. */
    public var url: String?
    /** This address is used for admin purposes, like new user notification. */
    public var email: String?
    /** A city in the same timezone as you. */
    public var timezone: String?
    /** A date format for all date strings. */
    public var dateFormat: String?
    /** A time format for all time strings. */
    public var timeFormat: String?
    /** A day number of the week that the week should start on. */
    public var startOfWeek: Int32?
    /** WordPress locale code. */
    public var language: String?
    /** Convert emoticons like :-) and :-P to graphics on display. */
    public var useSmilies: Bool?
    /** Default post category. */
    public var defaultCategory: Int32?
    /** Default post format. */
    public var defaultPostFormat: String?
    /** Blog pages show at most. */
    public var postsPerPage: Int32?
    /** Allow link notifications from other blogs (pingbacks and trackbacks) on new articles. */
    public var defaultPingStatus: DefaultPingStatus?
    /** Allow people to post comments on new articles. */
    public var defaultCommentStatus: DefaultCommentStatus?

    public init() {}

    // MARK: JSONEncodable
    open func encodeToJSON() -> Any {
        var nillableDictionary = [String:Any?]()
        nillableDictionary["title"] = self.title
        nillableDictionary["description"] = self.description
        nillableDictionary["url"] = self.url
        nillableDictionary["email"] = self.email
        nillableDictionary["timezone"] = self.timezone
        nillableDictionary["date_format"] = self.dateFormat
        nillableDictionary["time_format"] = self.timeFormat
        nillableDictionary["start_of_week"] = self.startOfWeek?.encodeToJSON()
        nillableDictionary["language"] = self.language
        nillableDictionary["use_smilies"] = self.useSmilies
        nillableDictionary["default_category"] = self.defaultCategory?.encodeToJSON()
        nillableDictionary["default_post_format"] = self.defaultPostFormat
        nillableDictionary["posts_per_page"] = self.postsPerPage?.encodeToJSON()
        nillableDictionary["default_ping_status"] = self.defaultPingStatus?.rawValue
        nillableDictionary["default_comment_status"] = self.defaultCommentStatus?.rawValue

        let dictionary: [String:Any] = APIHelper.rejectNil(nillableDictionary) ?? [:]
        return dictionary
    }
}

