/*
The MIT License (MIT)

Copyright (c) 2014 Shun Takebayashi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Foundation

public class PinboardClient {

    let endpoint = "https://api.pinboard.in/v1"
    let queue = NSOperationQueue.mainQueue()

    let username: String
    let token: String

    public init(username: String, token: String) {
        self.username = username
        self.token = token
    }

    func concatenateKeyAndValue(key: String, value: String) -> String {
        return key + "=" + value.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
    }

    public func validateToken(callback: (Bool, NSError?) -> Void) {
        sendRequest("/user/api_token", parameters: [:]) { json, error in
            if let _ = error {
                callback(false, error)
            }
            else if let result = json as? [String: String] {
                if result["result"] == self.token {
                    callback(true, nil);
                }
                else {
                    callback(false, nil)
                }
            }
            else {
                callback(false, PinboardError(code: .InvalidResponse))
            }
        }
    }

    func createRequest(path: String, parameters: [String: String]) -> NSURLRequest {
        var params = parameters
        params["auth_token"] = username + ":" + token
        params["format"] = "json"
        let qline = join("&", map(params, concatenateKeyAndValue))
        let url = NSURL(string: endpoint + path + "?" + qline)!
        return NSURLRequest(URL: url)
    }

    func sendRequest(path: String, parameters: [String: String], callback: (AnyObject?, NSError?) -> Void) {
        let request = createRequest(path, parameters: parameters)
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) { response, data, error in
            callback(self.handleResponse(response, data: data, error: error))
        }
    }

    func handleResponse(response: NSURLResponse, data: NSData, error: NSError?) -> (AnyObject?, NSError?) {
        if let _ = error {
            return (nil, error)
        }
        else if let http = response as? NSHTTPURLResponse {
            if http.statusCode != 200 {
                return (nil, NSError(domain: "CocoaPinboardHTTPError", code: http.statusCode, userInfo:nil))
            }
            else {
                var jsonError: NSError?
                let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
                return (json, jsonError)
            }
        }
        else {
            return (nil, PinboardError(code: .InvalidResponse))
        }
    }

    public func parseResponse(json: AnyObject) -> NSError? {
        if let response = json as? [String: String] {
            if response["result_code"] == "done" {
                return nil
            }
            else {
                return PinboardError(code: .ErrorResponse, message: response["result_code"])
            }
        }
        return PinboardError(code: .InvalidResponse)
    }

    public func addBookmark(bookmark: Bookmark, overwrite: Bool, callback: NSError? -> Void) {
        let params = [
            "url": bookmark.URLString,
            "description": bookmark.title,
            "tags": join(",", bookmark.tags),
            "replace": overwrite ? "yes" : "no"
        ]
        sendRequest("/posts/add", parameters: params) { json, error in
            callback(error ?? self.parseResponse(json!))
        }
    }

    public func addBookmark(url: String, title: String, tags: [String], callback: NSError? -> Void) {
        let bookmark = Bookmark(title: title, URLString: url, tags: tags)
        addBookmark(bookmark, overwrite: false) { error in
            callback(error)
        }
    }

    public func updateBookmark(bookmark: Bookmark, callback: NSError? -> Void) {
        addBookmark(bookmark, overwrite: true) { error in
            callback(error)
        }
    }

    public func getBookmakrs(callback: ([Bookmark]?, NSError?) -> Void) {
        sendRequest("/posts/all", parameters: [:]) { json, error in
            if let _ = error {
                callback(nil, error)
            }
            else if let entries = json as? [[String: String]] {
                let bookmarks = entries.map { Bookmark(json: $0) }
                callback(bookmarks, nil)
            }
            else {
                callback(nil, PinboardError(code: .InvalidResponse))
            }
        }
    }

    public func deleteBookmark(url: String, callback: NSError? -> Void) {
        let params = [
            "url": url
        ]
        sendRequest("/posts/delete", parameters: params) { json, error -> Void in
            callback(error)
        }
    }

    public func getRecommendedTags(url: String, callback: ([String]?, NSError?) -> Void) {
        sendRequest("/posts/suggest", parameters: ["url": url]) { json, error in
            if let _ = error {
                callback(nil, error)
            }
            else if let response = json as? [[String: [String]]] {
                let tags = response.flatMap { $0["recommended"] ?? [] }
                callback(tags, nil)
            }
            else {
                callback(nil, PinboardError(code: .InvalidResponse))
            }
        }
    }

    public func getCountsByDate(callback: ([String: Int]?, NSError?) -> Void) {
        sendRequest("/posts/date", parameters: [:]) { json, error in
            if let _ = error {
                callback(nil, error)
            }
            else {
                callback(self.parseCountsByDateResponse(json))
            }
        }
    }

    public func parseCountsByDateResponse(content: AnyObject?) -> ([String: Int]?, NSError?) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateContent = (content as? [String: AnyObject])?["dates"] as? [String: String]
        if let dates = dateContent {
            var counts: [String: Int] = [:]
            for date in dates.keys {
                counts[date] = dates[date]?.toInt()
            }
            return (counts, nil)
        }
        return (nil, PinboardError(code: .InvalidResponse, message: nil))
    }

}
