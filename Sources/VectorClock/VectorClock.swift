import Foundation

/// A Vector clock which ensures a total order by additionally adding a timestamp
public struct VectorClock<ActorID: Comparable & Hashable> {
    
    struct UnambigousTimestamp {
        var actorID: ActorID
        var timestamp: TimeInterval
    }
    
    public typealias TimestampProvider = () -> TimeInterval
    
    private var timestampProvider: TimestampProvider
    private var clocksByActors: [ActorID: Int]
    private var timestamp: UnambigousTimestamp
    
    // MARK: Lifecycle
    
    public init(actorID: ActorID, timestampProvider: @escaping TimestampProvider = { Date().timeIntervalSince1970 }) {
        self.timestampProvider = timestampProvider
        self.clocksByActors = [actorID: 0]
        self.timestamp = .init(actorID: actorID, timestamp: timestampProvider())
    }

    // MARK: - VectorClock
    
    func incrementing(_ actorID: ActorID) -> VectorClock {
        var incrementedClock = self
        incrementedClock.clocksByActors[actorID] = self.clocksByActors[actorID, default: 0] + 1
        incrementedClock.timestamp = .init(actorID: actorID, timestamp: self.timestampProvider())
        return incrementedClock
    }
    
    func merging(_ clock: VectorClock) -> VectorClock {
        var merged = self
        merged.clocksByActors = self.clocksByActors.merging(clock.clocksByActors) { max($0, $1) }
        merged.timestamp = max(self.timestamp, clock.timestamp)
        return merged
    }
}

// MARK: - Comparable

extension VectorClock.UnambigousTimestamp: Comparable {

    static func < (lhs: VectorClock<ActorID>.UnambigousTimestamp, rhs: VectorClock<ActorID>.UnambigousTimestamp) -> Bool {
        if lhs.timestamp == rhs.timestamp {
            return lhs.actorID < rhs.actorID
        } else {
            return lhs.timestamp < rhs.timestamp
        }
    }
}

extension VectorClock: Comparable {
    public static func == (lhs: VectorClock<ActorID>, rhs: VectorClock<ActorID>) -> Bool {
        return (lhs < rhs) == false && (rhs > lhs) == false
    }


    public static func < (lhs: VectorClock<ActorID>, rhs: VectorClock<ActorID>) -> Bool {
        var lhsGreater = false
        var rhsGreater = false
        let actors = Set(lhs.clocksByActors.keys).union(Set(rhs.clocksByActors.keys))
        for actor in actors {
            let lhsValue = lhs.clocksByActors[actor, default: 0]
            let rhsValue = rhs.clocksByActors[actor, default: 0]

            if lhsValue > rhsValue {
                lhsGreater = true
            } else if rhsValue > lhsValue {
                rhsGreater = true
            }
            if lhsGreater && rhsGreater {
                return lhs.timestamp < rhs.timestamp
            }
        }
        if lhsGreater != rhsGreater {
            return rhsGreater
        } else {
            return lhs.timestamp < rhs.timestamp
        }
    }
}

// MARK: CustomStringConvertible

extension VectorClock.UnambigousTimestamp: CustomStringConvertible {

    public var description: String {
        let formattedTimestamp = String(format: "%.2f", self.timestamp)
        return "t: \(self.actorID)(\(formattedTimestamp))"
    }
}

extension VectorClock: CustomStringConvertible {

    public var description: String {
        let clocks = self.clocksByActors.map { "\($0.key)=\($0.value)" }.sorted(by: <).joined(separator: ", ")
        return "<\(clocks) | \(self.timestamp)>"
    }
}
