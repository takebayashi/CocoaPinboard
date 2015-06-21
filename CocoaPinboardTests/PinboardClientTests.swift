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
import XCTest
import CocoaPinboard

class PinboardClientTests: XCTestCase {

    let client = PinboardClient(username: "", token: "")

    func parseJson(json: String) -> AnyObject {
        return NSJSONSerialization.JSONObjectWithData(
            json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!,
            options: nil,
            error: nil
        )!
    }

    func testParseResponse() {
        let failedJsonString = "{\"result_code\":\"item not found\"}"
        let failedJson: AnyObject = NSJSONSerialization.JSONObjectWithData(
            failedJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!,
            options: nil,
            error: nil
        )!
        let error = client.parseResponse(failedJson)
        XCTAssertEqual(error!.localizedDescription, "item not found")

        let succeededJsonString = "{\"result_code\":\"done\"}"
        let succeededJson: AnyObject = NSJSONSerialization.JSONObjectWithData(
            succeededJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!,
            options: nil,
            error: nil
            )!
        let noneError = client.parseResponse(succeededJson)
        XCTAssertNil(noneError)
    }

    func testParseCountsByDateResponse() {
        let jsonString = "{\"user\":\"argentina\",\"tag\":\"\",\"dates\":{\"2010-11-29\":\"5\",\"2010-11-28\":\"15\",\"2010-11-26\":\"2\"}}"
        let (counts, error) = client.parseCountsByDateResponse(parseJson(jsonString))
        XCTAssertNil(error)
        XCTAssertNotNil(counts)
        XCTAssertEqual(count(counts!), 3)
        XCTAssertEqual(counts!["2010-11-28"]!, 15)
    }

}
