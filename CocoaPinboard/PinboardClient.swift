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

open class PinboardClient {

    let username: String
    let token: String
    let queue: OperationQueue
    let endpoint: String

    public init(username: String,
                token: String,
                queue: OperationQueue = .main,
                endpoint: String = "https://api.pinboard.in/v1") {
        self.username = username
        self.token = token
        self.queue = queue
        self.endpoint = endpoint
    }

    func concatenateKeyAndValue(_ key: String, value: String) -> String {
        return key + "=" + value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }

    open func validateToken(_ callback: @escaping (Bool, Error?) -> Void) {
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
                callback(false, PinboardError(code: .invalidResponse))
            }
        }
    }

    func createRequest(_ path: String, parameters: [String: String]) -> URLRequest {
        var params = parameters
        params["auth_token"] = username + ":" + token
        params["format"] = "json"
        let qline = params.map(concatenateKeyAndValue).joined(separator: "&")
        let url = URL(string: endpoint + path + "?" + qline)!
        return URLRequest(url: url)
    }

    func sendRequest(_ path: String, parameters: [String: String], callback: @escaping (Any?, Error?) -> Void) {
        let request = createRequest(path, parameters: parameters)
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) { response, data, error in
            let (handledJson, handledError) = self.handleResponse(response!, data: data!, error: error)
            callback(handledJson, handledError)
        }
    }

    func handleResponse(_ response: URLResponse, data: Data, error: Error?) -> (Any?, Error?) {
        if let _ = error {
            return (nil, error)
        }
        else if let http = response as? HTTPURLResponse {
            if http.statusCode != 200 {
                return (nil, NSError(domain: "CocoaPinboardHTTPError", code: http.statusCode, userInfo:nil))
            }
            else {
                var jsonError: NSError?
                let json: Any?
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: [])
                } catch let error as NSError {
                    jsonError = error
                    json = nil
                }
                return (json, jsonError)
            }
        }
        else {
            return (nil, PinboardError(code: .invalidResponse))
        }
    }

    open func parseResponse(_ json: Any) -> Error? {
        if let response = json as? [String: String] {
            if let resultCode = response["result_code"] {
                if resultCode == "done" {
                    return nil
                }
                else {
                    return PinboardError(code: .errorResponse, message: resultCode)
                }
            }
            return PinboardError(code: .errorResponse)
        }
        return PinboardError(code: .invalidResponse)
    }

    open func addBookmark(_ bookmark: Bookmark, overwrite: Bool, callback: @escaping (Error?) -> Void) {
        let params = [
            "url": bookmark.URL.absoluteString,
            "description": bookmark.title,
            "extended": bookmark.extendedDescription,
            "tags": bookmark.tags.joined(separator: ","),
            "replace": overwrite ? "yes" : "no"
        ]
        sendRequest("/posts/add", parameters: params) { json, error in
            callback(error ?? self.parseResponse(json!))
        }
    }

    open func updateBookmark(_ bookmark: Bookmark, callback: @escaping (Error?) -> Void) {
        addBookmark(bookmark, overwrite: true) { error in
            callback(error)
        }
    }

    open func getBookmakrs(_ callback: @escaping ([Bookmark]?, Error?) -> Void) {
        sendRequest("/posts/all", parameters: [:]) { json, error in
            if let _ = error {
                callback(nil, error)
            }
            else if let entries = json as? [[String: String]] {
                let bookmarks = entries.flatMap(BookmarkParser.parse)
                callback(bookmarks, nil)
            }
            else {
                callback(nil, PinboardError(code: .invalidResponse))
            }
        }
    }

    open func deleteBookmark(_ url: String, callback: @escaping (Error?) -> Void) {
        let params = [
            "url": url
        ]
        sendRequest("/posts/delete", parameters: params) { json, error -> Void in
            callback(error)
        }
    }

    open func getRecommendedTags(_ url: String, callback: @escaping ([String]?, Error?) -> Void) {
        sendRequest("/posts/suggest", parameters: ["url": url]) { json, error in
            if let _ = error {
                callback(nil, error)
            }
            else if let response = json as? [[String: [String]]] {
                let tags = response.flatMap { $0["recommended"] ?? [] }
                callback(tags, nil)
            }
            else {
                callback(nil, PinboardError(code: .invalidResponse))
            }
        }
    }

    open func getCountsByDate(_ callback: @escaping ([String: Int]?, Error?) -> Void) {
        sendRequest("/posts/date", parameters: [:]) { json, error in
            if let _ = error {
                callback(nil, error)
            }
            else {
                let (handledJson, handledError) = self.parseCountsByDateResponse(json)
                callback(handledJson, handledError)
            }
        }
    }

    open func parseCountsByDateResponse(_ content: Any?) -> ([String: Int]?, NSError?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateContent = (content as? [String: AnyObject])?["dates"] as? [String: String]
        if let dates = dateContent {
            var counts: [String: Int] = [:]
            for date in dates.keys {
                counts[date] = Int(dates[date]!)
            }
            return (counts, nil)
        }
        return (nil, PinboardError(code: .invalidResponse, message: nil))
    }

}
