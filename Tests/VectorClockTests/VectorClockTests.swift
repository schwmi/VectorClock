import XCTest
@testable import VectorClock


final class VectorClockTests: XCTestCase {
    
    func testNewEmptyClock() {
        let clock = VectorClock(actorID: "A", timestampProviderStrategy: .monotonicIncrease)
        XCTAssertEqual(clock.description, "<A=0 | t: A(1.00)>")
    }
    
    func testIncrement() {
        let clock = VectorClock(actorID: "A", timestampProviderStrategy: .monotonicIncrease)
        
        // Increment actor A
        let incrementedA = clock.incrementing("A")
        XCTAssertEqual(incrementedA.description, "<A=1 | t: A(2.00)>")
        
        // Increment actor B
        let incrementedAB = incrementedA.incrementing("B")
        XCTAssertEqual(incrementedAB.description, "<A=1, B=1 | t: B(3.00)>")
        
        // Increment actor B again
        let incrementedABB = incrementedAB.incrementing("B")
        XCTAssertEqual(incrementedABB.description, "<A=1, B=2 | t: B(4.00)>")
        
        // Increment actor A again
        let incrementedABBA = incrementedABB.incrementing("A")
        XCTAssertEqual(incrementedABBA.description, "<A=2, B=2 | t: A(5.00)>")
    }
    
    func testMerge() {
        let clock = VectorClock(actorID: "A", timestampProviderStrategy: .monotonicIncrease)
        
        // Increment actor A
        let incrementedA = clock.incrementing("A")
        XCTAssertEqual(incrementedA.description, "<A=1 | t: A(2.00)>")
        
        // Increment actor B
        let incrementedB = clock.incrementing("B")
        XCTAssertEqual(incrementedB.description, "<A=0, B=1 | t: B(3.00)>")
        
        // Merge A with B
        let mergedAB = incrementedB.merging(incrementedA)
        XCTAssertEqual(mergedAB.description, "<A=1, B=1 | t: B(3.00)>")
    }
    
    func testComparisonWithConstantTime() {
        // Test empty clock comparison
        let clock1 = VectorClock(actorID: "A", timestampProviderStrategy: .constant)
        let clock2 = VectorClock(actorID: "A", timestampProviderStrategy: .constant)
        XCTAssertEqual(clock1, clock2)
        
        // Increment actor A
        let clock1A = clock1.incrementing("A")
        XCTAssertTrue(clock1 < clock1A)
        XCTAssertTrue(clock1A == clock1A)
        
        // Increment actor B
        let clock2B = clock2.incrementing("B")
        XCTAssertEqual(clock1A.partialOrder(other: clock2B), .concurrent)
        XCTAssertTrue(clock1A < clock2B)
        XCTAssertFalse(clock1A > clock2B)
    }
    
    func testComparisonWithIncreasingTime() {
        // Test empty clock comparison
        let clock1 = VectorClock(actorID: "A", timestampProviderStrategy: .unixTime)
        Thread.sleep(forTimeInterval: 0.01)
        let clock2 = VectorClock(actorID: "A",  timestampProviderStrategy: .unixTime)
        XCTAssertEqual(clock1.partialOrder(other: clock2), .concurrent)
        XCTAssertTrue(clock1 < clock2)
        
        // Increment actor A
        let clock1A = clock1.incrementing("A")
        XCTAssertTrue(clock1 < clock1A)
        XCTAssertTrue(clock1A == clock1A)
        
        // Increment actor B
        let clock2B = clock2.incrementing("B")
        XCTAssertTrue(clock1A < clock2B)
    }

    func testSortingPerformance() {
        var clocks = Set<VectorClock<String>>()
        let actors = ["A", "B", "C", "D"]
        let clock = VectorClock(actorID: "A", timestampProviderStrategy: .monotonicIncrease)
        clocks.insert(clock)
        for _ in 0..<5000 {
            clocks.insert(clock.incrementing(actors.randomElement()!))
        }
        self.measure {
            _ = clocks.sorted()
        }
    }

    func testCodable() throws {
        let clock = VectorClock(actorID: "A", timestampProviderStrategy: .monotonicIncrease)
        let encoded = try JSONEncoder().encode(clock)
        let decoded = try JSONDecoder().decode(VectorClock<String>.self, from: encoded)
        XCTAssertEqual(clock, decoded)
        let increasedClock = decoded.incrementing("B")
        print(increasedClock.description)
        XCTAssertEqual(increasedClock.description, "<A=0, B=1 | t: B(2.00)>")
    }

    static var allTests = [
        ("testIncrement", testIncrement),
        ("testComparisonWithConstantTime", testComparisonWithConstantTime),
        ("testComparisonWithIncreasingTime", testComparisonWithIncreasingTime),
        ("testMerge", testMerge),
        ("testNewEmptyClock", testNewEmptyClock)
    ]
}
