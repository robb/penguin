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
  private let uniqueUnlabeledTuples = (0..<9).map { ($0, String($0)) }
  private let uniqueLabeledTuples
    = (0..<9).map { (key: $0, value: String($0)) }
  private let uniqueKeyValues = (0..<9).map {
    KeyValuePair(key: $0, value: String($0))
  }
  
  func test_interopFunctions() {
    var d = NominalElementDictionary<Int, String>()
    d.merge(uniqueUnlabeledTuples.keyValuePairs()) { _,_ in fatalError() }
    XCTAssert(uniqueUnlabeledTuples.allSatisfy { d[$0.0] == $0.1 })

    d.removeAll()
    d.merge(uniqueLabeledTuples.keyValuePairs()) { _,_ in fatalError() }
    XCTAssert(uniqueLabeledTuples.allSatisfy { d[$0.key] == $0.value })

    XCTAssert(d.keyValueTuples().count == d.count)
    XCTAssert(d.keyValueTuples().allSatisfy { d[$0.0] == $0.1 } )
  }

  func test_collectionSemantics() {
    let d = NominalElementDictionary(uniqueKeysWithValues: uniqueKeyValues)
    let expectedValues = uniqueKeyValues.sorted {
      d.index(forKey: $0.key) ?? d.endIndex
        < d.index(forKey: $1.key) ?? d.endIndex
    }
    d.checkCollectionSemantics(expectedValues: expectedValues)
  }

  func test_initFromDictionary() {
    let d0: [Int: String] = .init(uniqueKeysWithValues: uniqueLabeledTuples)
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

  func test_initUniqueKeysWithValues() {
    let d = NominalElementDictionary(uniqueKeysWithValues: uniqueKeyValues)
    XCTAssertEqual(d.count, uniqueKeyValues.count)
    XCTAssert(uniqueKeyValues.allSatisfy { d[$0.key] == $0.value })
    // TODO: test for traps when keys are not unique.
  }

  static var allTests = [
    ("test_interopFunctions", test_interopFunctions),
    ("test_collectionSemantics", test_collectionSemantics),
    ("test_initFromDictionary", test_initFromDictionary),
    ("test_defaultInit", test_defaultInit),
    ("test_initMinimumCapacity", test_initMinimumCapacity),
    ("test_initUniqueKeysWithValues", test_initUniqueKeysWithValues),
  ]
}

