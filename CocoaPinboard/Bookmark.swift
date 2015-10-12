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

public class Bookmark: NSObject, NSCopying {

    init(URLString: String) {
        self.URLString = URLString
        self.tags = []
        self.title = ""
        self.extendedDescription = ""
    }

    public init(json: [String: String]) {
        if let tagLine = json["tags"] {
            self.tags = tagLine.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        }
        else {
            self.tags = []
        }
        self.URLString = json["href"] ?? ""
        self.title = json["description"] ?? ""
        self.extendedDescription = json["extended"] ?? ""
        self.signature = json["meta"]
    }

    public var tags: [String]
    public var URLString: String
    public var title: String
    public var extendedDescription: String
    public var signature: String?

    public func copyWithZone(zone: NSZone) -> AnyObject {
        let copied = Bookmark(URLString: self.URLString)
        copied.tags = self.tags
        copied.title = self.title
        copied.extendedDescription = self.extendedDescription
        copied.signature = self.signature
        return copied
    }

}
