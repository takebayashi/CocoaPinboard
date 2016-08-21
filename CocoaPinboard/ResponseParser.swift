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

public struct BookmarkParser {

    public static func parse(_ JSON: [String: String]) -> Bookmark? {
        guard let url = URL(string: JSON["href"] ?? "") else {
            return nil
        }
        let bookmark = Bookmark(URL: url)
        if let tags = JSON["tags"]?.components(separatedBy: CharacterSet.whitespaces) {
            bookmark.tags = tags
        }
        bookmark.title = JSON["description"] ?? ""
        bookmark.extendedDescription = JSON["extended"] ?? ""
        bookmark.date = DateParser.parse(JSON["dt"] ?? "")
        bookmark.signature = JSON["meta"]
        return bookmark
    }

}

public struct DateParser {

    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z"
        return formatter
    }()

    public static func parse(_ string: String) -> Date? {
        return dateFormatter.date(from: string)
    }

}
