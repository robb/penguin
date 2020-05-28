//******************************************************************************
// Copyright 2020 Penguin Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import XCTest
import PenguinStructures

final class NominalElementDictionaryTests: XCTestCase {
  func test_interopFunctions() {
    let s0 = (0..<9).lazy.map { ($0, String($0)) }
    var d = NominalElementDictionary<Int, String>()
    d.merge(s0.keyValuePairs()) { _,_ in fatalError() }
    XCTAssert(s0.allSatisfy { d[$0.0] == $0.1 })

    d.removeAll()
    let s1 = (0..<9).lazy.map { (key: $0, value: String($0)) }
    d.merge(s1.keyValuePairs()) { _,_ in fatalError() }
    XCTAssert(s1.allSatisfy { d[$0.key] == $0.value })

    XCTAssert(d.keyValueTuples().count == d.count)
    XCTAssert(d.keyValueTuples().allSatisfy { d[$0.0] == $0.1 } )
  }

  func test_collectionSemantics() {
    let contents = (0..<9).map { KeyValuePair(key: $0, value: String($0)) }
    let d = NominalElementDictionary(uniqueKeysWithValues: contents)
    let expectedValues = contents.sorted {
      d.index(forKey: $0.key) ?? d.endIndex
        < d.index(forKey: $1.key) ?? d.endIndex
    }
    d.checkCollectionSemantics(expectedValues: expectedValues)
  }

  func test_initFromDictionary() {
    let d0: [Int: String] = .init(
      uniqueKeysWithValues: (0..<9).map { (key: $0, value: String($0)) })
    let d1 = NominalElementDictionary(d0)
    XCTAssertEqual(Array(d0.keyValuePairs()), Array(d1))
  }
  
  func test_defaultInit() {
    let d = NominalElementDictionary<Int, String>()
    XCTAssert(d.isEmpty)
  }

  func test_initMinimumCapacity() {
    let d = NominalElementDictionary<Int, String>(minimumCapacity: 100)
    XCTAssert(d.capacity >= 100)
  }
  
  static var allTests = [
    ("test_interopFunctions", test_interopFunctions),
    ("test_collectionSemantics", test_collectionSemantics),
    ("test_initFromDictionary", test_initFromDictionary),
    ("test_defaultInit", test_defaultInit),
    ("test_initMinimumCapacity", test_initMinimumCapacity),
  ]
}

