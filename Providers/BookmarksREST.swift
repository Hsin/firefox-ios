// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Alamofire

/*
class TestBookmarksProvider : BookmarksREST {
    override func getAll(success: ([Bookmark]) -> (), error: (RequestError) -> ()) {
        var res = [Bookmark]()
        for i in 0...10 {
            var b = Bookmark(title: "Title \(i)", url: "http://www.example.com/\(i)")
            res.append(b)
        }
        success(res)
    }
}
*/

public class BookmarksREST: BookmarksModel {
    private let account: Account

    init(account: Account) {
        self.account = account
    }

    override public func reloadData() {
        account.makeAuthRequest(
            "bookmarks/recent",
            success: { data in
                self.parseResponse(data);
            },
            error: { error in
                // TODO
            })
    }

    private func parseResponse(response: AnyObject?) {
        var resp : [BookmarkItem] = [];

        if let response: NSArray = response as? NSArray {
            for bookmark in response {
                var title: String = ""
                var url: String = ""
                var guid: String

                if let t = bookmark.valueForKey("title") as? String {
                    title = t
                } else {
                    continue;
                }

                if let u = bookmark.valueForKey("bmkUri") as? String {
                    url = u
                } else {
                    continue;
                }

                if let id = bookmark.valueForKey("id") as? String {
                    guid = id
                } else {
                    continue;
                }

                resp.append(BookmarkItem(id: guid, title: title, url: url))
            }
        }

        self.root.children = resp
    }
    
    /// Send a ShareItem to this user's bookmarks
    ///
    /// :param: item    the item to be sent
    ///
    /// Note that this code currently uses NSURLSession directly because AlamoFire
    /// does not work from an Extension. (Bug 1104884)
    ///
    /// Note that the bookmark will end up in the Unsorted Bookmarks. We have Bug
    /// 1094233 open for the REST API to store the incoming item in the Mobile
    /// Bookmarks instead.
    /*
    func shareItem(item: ShareItem) {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://moz-syncapi.sateh.com/1.0/bookmarks")!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.HTTPMethod = "POST"
        
        var object = NSMutableDictionary()
        object["url"] = item.url
        object["title"] = item.title == nil ? "" : item.title
        
        var jsonError: NSError?
        let data = NSJSONSerialization.dataWithJSONObject(object, options: nil, error: &jsonError)
        if data != nil {
            request.HTTPBody = data
        }
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("Bookmarks/shareItem")
        configuration.HTTPAdditionalHeaders = ["Authorization" : account.basicAuthorizationHeader()]
        configuration.sharedContainerIdentifier = ExtensionUtils.sharedContainerIdentifier()
        
        let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        let task = session.dataTaskWithRequest(request)
        task.resume()
    }
    */
}
