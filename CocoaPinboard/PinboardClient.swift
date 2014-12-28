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

class PinboardClient {
    
    let endpoint = "https://api.pinboard.in/v1"
    let queue = NSOperationQueue.mainQueue()
    
    let username: String
    let token: String
    
    init(username: String, token: String) {
        self.username = username
        self.token = token
    }
    
    typealias Callback = (AnyObject?, NSError?) -> Void
    
    func concatenateKeyAndValue(key: String, value: String) -> String {
        return key + "=" + value.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
    }
    
    func sendRequest(path: String, parameters: [String: String], callback: Callback) {
        var params = parameters
        params["auth_token"] = username + ":" + token
        let qline = join("&", map(params, concatenateKeyAndValue))
        let url = NSURL(string: endpoint + path + "?" + qline)!
        let request = NSURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) { response, data, error in
            if error != nil {
                callback(nil, error)
                return
            }
            if let http = response as? NSHTTPURLResponse {
                if http.statusCode != 200 {
                    callback(nil, NSError(domain: "CocoaPinboardHTTPError", code: http.statusCode, userInfo:nil))
                }
            }
            var jsonError: NSError?
            let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
            callback(json, jsonError)
        }
    }
    
}
