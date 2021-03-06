//
// Comment.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation


open class Comment: JSONEncodable {

    /** Unique identifier for the object. */
    public var id: Int32?
    /** The ID of the user object, if author was a user. */
    public var author: Int32?
    /** Email address for the object author. */
    public var authorEmail: String?
    /** IP address for the object author. */
    public var authorIp: String?
    /** Display name for the object author. */
    public var authorName: String?
    /** URL for the object author. */
    public var authorUrl: String?
    /** User agent for the object author. */
    public var authorUserAgent: String?
    public var content: CommentContent?
    /** The date the object was published, in the site&#39;s timezone. */
    public var date: Date?
    /** The date the object was published, as GMT. */
    public var dateGmt: Date?
    /** URL to the object. */
    public var link: String?
    /** The ID for the parent of the object. */
    public var parent: Int32?
    /** The ID of the associated post object. */
    public var post: Int32?
    /** State of the object. */
    public var status: String?
    /** Type of Comment for the object. */
    public var type: String?
    public var authorAvatarUrls: CommentAuthorAvatarUrls?
    /** Meta fields. */
    public var meta: Any?

    public init() {}

    // MARK: JSONEncodable
    open func encodeToJSON() -> Any {
        var nillableDictionary = [String:Any?]()
        nillableDictionary["id"] = self.id?.encodeToJSON()
        nillableDictionary["author"] = self.author?.encodeToJSON()
        nillableDictionary["author_email"] = self.authorEmail
        nillableDictionary["author_ip"] = self.authorIp
        nillableDictionary["author_name"] = self.authorName
        nillableDictionary["author_url"] = self.authorUrl
        nillableDictionary["author_user_agent"] = self.authorUserAgent
        nillableDictionary["content"] = self.content?.encodeToJSON()
        nillableDictionary["date"] = self.date?.encodeToJSON()
        nillableDictionary["date_gmt"] = self.dateGmt?.encodeToJSON()
        nillableDictionary["link"] = self.link
        nillableDictionary["parent"] = self.parent?.encodeToJSON()
        nillableDictionary["post"] = self.post?.encodeToJSON()
        nillableDictionary["status"] = self.status
        nillableDictionary["type"] = self.type
        nillableDictionary["author_avatar_urls"] = self.authorAvatarUrls?.encodeToJSON()
        nillableDictionary["meta"] = self.meta

        let dictionary: [String:Any] = APIHelper.rejectNil(nillableDictionary) ?? [:]
        return dictionary
    }
}

