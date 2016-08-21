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

    func parseJson(_ json: String) -> Any {
        return try! JSONSerialization.jsonObject(
            with: json.data(using: String.Encoding.utf8, allowLossyConversion: false)!,
            options: [])
    }

    func testParseResponse() {
        let failedJsonString = "{\"result_code\":\"item not found\"}"
        let failedJson = try! JSONSerialization.jsonObject(
            with: failedJsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!,
            options: [])
        if let error = client.parseResponse(failedJson) {
            XCTAssertTrue(error.localizedDescription == "item not found")
        }
        else {
            XCTFail("error should be occurred, but not")
        }

        let succeededJsonString = "{\"result_code\":\"done\"}"
        let succeededJson = try! JSONSerialization.jsonObject(
            with: succeededJsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!,
            options: [])
        let noneError = client.parseResponse(succeededJson)
        XCTAssertNil(noneError)
    }

    func testParseCountsByDateResponse() {
        let jsonString = "{\"user\":\"argentina\",\"tag\":\"\",\"dates\":{\"2010-11-29\":\"5\",\"2010-11-28\":\"15\",\"2010-11-26\":\"2\"}}"
        let (counts, error) = client.parseCountsByDateResponse(parseJson(jsonString))
        XCTAssertNil(error)
        XCTAssertNotNil(counts)
        XCTAssertEqual((counts!).count, 3)
        XCTAssertEqual(counts!["2010-11-28"]!, 15)
    }

}
