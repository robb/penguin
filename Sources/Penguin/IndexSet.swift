// Copyright 2020 Penguin Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


public struct PIndexSet: Equatable {

    public init(indices: [Int], count: Int?) {
        guard let size = count ?? indices.max() else {
            preconditionFailure("indicies (or count) must be provided and non-empty.")
        }
        self.impl = Array(repeating: false, count: size)
        self.setCount = indices.count
        for index in indices {
            self.impl[index] = true
        }
    }

    public init(all: Bool, count: Int) {
        // TODO: Optimize internal representation!
        self.impl = Array(repeating: all, count: count)
        self.setCount = all ? count : 0
    }

    init(_ bitset: [Bool], setCount: Int) {
        self.setCount = setCount
        self.impl = bitset
    }

    init(empty dummy: Bool) {
        self.init(all: false, count: 0)
    }

    public mutating func union(_ rhs: PIndexSet, extending: Bool? = nil) throws {
        if count != rhs.count {
            if extending == nil || extending == false {
                throw PError.indexSetMisMatch(lhs: count, rhs: rhs.count, extendingAvailable: extending == nil)
            }
            self.impl.reserveCapacity(max(count, rhs.count))
        }
        let unionStop = min(count, rhs.count)
        var newSetCount = 0
        for i in 0..<unionStop {
            let newValue = self.impl[i] || rhs.impl[i]
            newSetCount += newValue.asInt
            self.impl[i] = newValue
        }
        if count < rhs.count {
            self.impl.append(contentsOf: rhs.impl[unionStop...])
            for i in unionStop..<rhs.impl.count {
                newSetCount += rhs.impl[i].asInt
            }
        } else {
            for i in unionStop..<impl.count {
                newSetCount += impl[i].asInt
            }
        }
        self.setCount = newSetCount
    }

    public func unioned(_ rhs: PIndexSet, extending: Bool? = nil) throws -> PIndexSet {
        var copy = self
        try copy.union(rhs, extending: extending)
        return copy
    }

    public mutating func intersect(_ rhs: PIndexSet, extending: Bool? = nil) throws {
        if count != rhs.count {
            if extending == nil || extending == false {
                throw PError.indexSetMisMatch(lhs: count, rhs: rhs.count, extendingAvailable: extending == nil)
            }
            self.impl.reserveCapacity(rhs.count)
        }
        let intersectionStop = min(count, rhs.count)
        let newSize = max(count, rhs.count)
        var newSetCount = 0
        for i in 0..<intersectionStop {
            let newValue = self.impl[i] && rhs.impl[i]
            newSetCount += newValue.asInt
            self.impl[i] = newValue
        }
        self.setCount = newSetCount
        if count < rhs.count {
            for _ in intersectionStop..<newSize {
                self.impl.append(false)
            }
        } else {
            for i in intersectionStop..<newSize {
                self.impl[i] = false
            }
        }
    }

    public func intersected(_ rhs: PIndexSet, extending: Bool? = nil) throws -> PIndexSet {
        var copy = self
        try copy.intersect(rhs, extending: extending)
        return copy
    }

    public static prefix func ! (a: PIndexSet) -> PIndexSet {
        let bitSet = a.count - a.setCount
        if bitSet == 0 {
            return PIndexSet(Array(repeating: false, count: a.count), setCount: 0)
        }
        if bitSet == a.count {
            return PIndexSet(Array(repeating: false, count: a.count), setCount: a.count)
        }
        var newSet = [Bool]()
        newSet.reserveCapacity(a.count)
        for b in a.impl {
            newSet.append(!b)
        }
        return PIndexSet(newSet, setCount: bitSet)
    }

    public var count: Int {
        impl.count
    }

    public var isEmpty: Bool {
        setCount == 0
    }

    subscript(i: Int) -> Bool {
        get {
            impl[i]
        }
        set {
            impl[i] = newValue
        }
    }

    mutating func append(_ value: Bool) {
        impl.append(value)
        if value {
            setCount += 1
        }
    }

    mutating func sort(_ indices: [Int]) {
        var newImpl = [Bool]()
        newImpl.reserveCapacity(impl.count)
        for index in indices {
            newImpl.append(impl[index])
        }
        self.impl = newImpl
    }

    func sorted(_ indices: [Int]) -> Self {
        var copy = self
        copy.sort(indices)
        return copy
    }

    public private(set) var setCount: Int
    var impl: [Bool]  // TODO: support alternate representations.
}

extension PIndexSet {
    func makeIterator() -> PIndexSetIterator<Array<Bool>.Iterator> {
        PIndexSetIterator(underlying: impl.makeIterator())
    }
}

// We don't want to make public key APIs on PIndexSet that would be required
// if we were to conform PIndexSet to the Collection protocol. So instead we
// implement our own iterator.
struct PIndexSetIterator<Underlying: IteratorProtocol>: IteratorProtocol where Underlying.Element == Bool {
    mutating func next() -> Bool? {
        underlying.next()
    }

    var underlying: Underlying
}


extension Bool {
    var asInt: Int {
        switch self {
        case false:
            return 0
        case true:
            return 1
        }
    }
}
