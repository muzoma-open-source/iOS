//
//  DiscoverRemoteDocs.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 30/11/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation
import Alamofire

//http://www.muzoma.co.uk/wp-json/wp/v2/media/?filter[taxonomy]=category&filter[field]=slug&filter[term]=movies



//https://www.muzoma.com/wp-json/wp/v2/media
//http://www.muzoma.co.uk/wp-json/wp/v2/media
//http://muzoma.co.uk/wp-json/wp/v2/pages/5
//http://muzoma.co.uk/wp-json/wp/v2/media/80
//http://muzoma.co.uk/wp-json/wp/v2/media?search=impos
//http://www.muzoma.co.uk/wp-json/wp/v2/media?media_type=audio
//http://www.muzoma.co.uk/wp-json/wp/v2/media?media_type=image

//http://www.muzoma.co.uk/wp-json/wp/v2/media?slug=muzoma-the-impossible-dream
//http://www.muzoma.co.uk/wp-json/wp/v2/media?slug=impossible-dream-200x200

/*
 [{"id":37,"date":"2016-10-11T16:32:22","date_gmt":"2016-10-11T16:32:22","guid":{"rendered":"http:\/\/muzoma.co.uk\/wp-content\/uploads\/2016\/10\/Muzoma-The-Impossible-Dream.muz"},"modified":"2016-10-11T16:32:22","modified_gmt":"2016-10-11T16:32:22","slug":"muzoma-the-impossible-dream","type":"attachment","link":"http:\/\/muzoma.co.uk\/muzoma-demo-songs\/muzoma-the-impossible-dream\/","title":{"rendered":"muzoma-the-impossible-dream"},"author":1,"comment_status":"closed","ping_status":"closed","alt_text":"","caption":"","description":"","media_type":"file","mime_type":"application\/muz","media_details":{},"post":5,"source_url":"http:\/\/muzoma.co.uk\/wp-content\/uploads\/2016\/10\/Muzoma-The-Impossible-Dream.muz","_links":{"self":[{"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/media\/37"}],"collection":[{"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/media"}],"about":[{"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/types\/attachment"}],"author":[{"embeddable":true,"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/users\/1"}],"replies":[{"embeddable":true,"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/comments?post=37"}]}}]
 */

//http://www.muzoma.co.uk/wp-json/wp/v2/media?mime_type=application/muz

/*
 [{"id":37,"date":"2016-10-11T16:32:22","date_gmt":"2016-10-11T16:32:22","guid":{"rendered":"http:\/\/muzoma.co.uk\/wp-content\/uploads\/2016\/10\/Muzoma-The-Impossible-Dream.muz"},"modified":"2016-10-11T16:32:22","modified_gmt":"2016-10-11T16:32:22","slug":"muzoma-the-impossible-dream","type":"attachment","link":"http:\/\/muzoma.co.uk\/muzoma-demo-songs\/muzoma-the-impossible-dream\/","title":{"rendered":"muzoma-the-impossible-dream"},"author":1,"comment_status":"closed","ping_status":"closed","alt_text":"","caption":"","description":"","media_type":"file","mime_type":"application\/muz","media_details":{},"post":5,"source_url":"http:\/\/muzoma.co.uk\/wp-content\/uploads\/2016\/10\/Muzoma-The-Impossible-Dream.muz","_links":{"self":[{"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/media\/37"}],"collection":[{"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/media"}],"about":[{"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/types\/attachment"}],"author":[{"embeddable":true,"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/users\/1"}],"replies":[{"embeddable":true,"href":"http:\/\/muzoma.co.uk\/wp-json\/wp\/v2\/comments?post=37"}]}},{"id":19,"date":"2016-09-19T10:06:12"
 
 ....
 
 */
/*
 Source (
 {
 "_links" =         {
 about =             (
 {
 href = "http://muzoma.co.uk/wp-json/wp/v2/types/attachment";
 }
 );
 author =             (
 {
 embeddable = 1;
 href = "http://muzoma.co.uk/wp-json/wp/v2/users/1";
 }
 );
 collection =             (
 {
 href = "http://muzoma.co.uk/wp-json/wp/v2/media";
 }
 );
 replies =             (
 {
 embeddable = 1;
 href = "http://muzoma.co.uk/wp-json/wp/v2/comments?post=37";
 }
 );
 self =             (
 {
 href = "http://muzoma.co.uk/wp-json/wp/v2/media/37";
 }
 );
 };
 "alt_text" = "";
 author = 1;
 caption = "Muzoma - The Impossible Dream";
 "comment_status" = closed;
 date = "2016-10-11T16:32:22";
 "date_gmt" = "2016-10-11T16:32:22";
 description = "<strong>The Impossible Dream</strong>
 \n<strong>By Muzoma</strong>
 \nWritten by Matt Hopkins
 \nDemo song for the Muzoma App and associated iBook user guide
 \n";
 guid =         {
 rendered = "http://muzoma.co.uk/wp-content/uploads/2016/10/Muzoma-The-Impossible-Dream.muz";
 };
 id = 37;
 link = "http://muzoma.co.uk/muzoma-demo-songs/muzoma-the-impossible-dream/";
 "media_details" =         {
 };
 "media_type" = file;
 meta =         {
 };
 "mime_type" = "application/muz";
 modified = "2016-11-30T17:14:16";
 "modified_gmt" = "2016-11-30T17:14:16";
 "ping_status" = closed;
 post = 5;
 slug = "muzoma-the-impossible-dream";
 "source_url" = "http://muzoma.co.uk/wp-content/uploads/2016/10/Muzoma-The-Impossible-Dream.muz";
 title =         {
 rendered = "muzoma-the-impossible-dream";
 };
 type = attachment;
 }
 ) is not convertible to type WPMediaBindingModel: Maybe swagger file is insufficient: file /Users/matthewhopkins/Documents/Dev/Event Sequencer/Event Sequencer/Event Sequencer/Swaggers/Models.swift, line 79
 */



//http://muzoma.co.uk/wp-json/apigenerate/swagger
/*
 public class WPMediaBindingModel: JSONEncodable {
 public var id: String?
    public var date: String?
 
 
    public init() {}
 
    // MARK: JSONEncodable
    func encodeToJSON() -> AnyObject {
        var nillableDictionary = [String:AnyObject?]()
        nillableDictionary["id"] = self.id
        nillableDictionary["date"] = self.date
        let dictionary: [String:AnyObject] = APIHelper.rejectNil(nillableDictionary) ?? [:]
        return dictionary
    }
}
*/
/*
public class RequestMedia: APIBase {
 
    public class func mediaGetWithRequestBuilder() -> RequestBuilder<WPMediaBindingModel> {
 
        let URLString = "http://www.muzoma.co.uk/wp-json/wp/v2/media?slug=muzoma-the-impossible-dream"
 
        let nillableParameters: [String:AnyObject?] = [:]
        
        let parameters = APIHelper.rejectNil(nillableParameters)
        
        let convertedParameters = APIHelper.convertBoolToString(parameters)
        
        let requestBuilder: RequestBuilder<WPMediaBindingModel>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()
        
        return requestBuilder.init(method: "GET", URLString: URLString, parameters: convertedParameters, isBody: true)
    }
}
*/

// With Alamofire
/*
 func fetchAllRooms(completion: ([RemoteRoom]?) -> Void) {
 Alamofire.request(
 .GET,
 "http://localhost:5984/rooms/_all_docs",
 parameters: ["include_docs": "true"],
 encoding: .URL)
 .validate()
 .responseJSON { (response) -> Void in
 guard response.result.isSuccess else {
 print("Error while fetching remote rooms: \(response.result.error)")
 completion(nil)
 return
 }
 
 guard let value = response.result.value as? [String: AnyObject],
 rows = value["rows"] as? [[String: AnyObject]] else {
 print("Malformed data received from fetchAllRooms service")
 completion(nil)
 return
 }
 
 var rooms = [RemoteRoom]()
 for roomDict in rows {
 rooms.append(RemoteRoom(jsonData: roomDict))
 }
 
 completion(rooms)
 }
 }
 */
