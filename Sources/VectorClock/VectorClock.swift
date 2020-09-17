import Foundation


/// A Vector clock which ensures a total order by additionally adding a timestamp
public struct VectorClock<ActorID: Comparable & Hashable & Codable> {

    public enum TimestampProviderStrategy: Int, Codable {
        case unixTime
        /// start by 1.0, increase by 1.0 (primarily for testing purposes)
        case monotonicIncrease
        // Always returns constant timestampe (0.0)
        case constant
    }

    public enum PartialOrder {
        case before
        case after
        case concurrent
    }
    
    struct UnambigousTimestamp: Hashable, Codable {
        var actorID: ActorID
        var timestamp: TimeInterval
    }

    private let timestampProvider: () -> TimeInterval
    private var timestampProviderStrategy: TimestampProviderStrategy
    private var clocksByActors: [ActorID: Int]
    private var timestamp: UnambigousTimestamp
    
    // MARK: Lifecycle
    
    public init(actorID: ActorID, timestampProviderStrategy: TimestampProviderStrategy = .unixTime) {
        self.timestampProviderStrategy = timestampProviderStrategy
        self.clocksByActors = [actorID: 0]
        self.timestampProvider = timestampProviderStrategy.makeProvider()
        self.timestamp = .init(actorID: actorID, timestamp: self.timestampProvider())
    }

    // MARK: - VectorClock

    /// Returns an incremented VectorClock
    /// - Parameter actorID: ActorID which is responsible for the increment
    /// - Returns: A new, incremented clock
    public func incrementing(_ actorID: ActorID) -> VectorClock {
        var incrementedClock = self
        incrementedClock.clocksByActors[actorID] = self.clocksByActors[actorID, default: 0] + 1
        incrementedClock.timestamp = .init(actorID: actorID, timestamp: self.timestampProvider())
        return incrementedClock
    }

    /// Returns a new, merged vector clock (max vectors)
    /// - Parameter clock: The clock which should be merged with
    /// - Returns: A new clock, representing the merged state
    public func merging(_ clock: VectorClock) -> VectorClock {
        var merged = self
        merged.clocksByActors = self.clocksByActors.merging(clock.clocksByActors) { max($0, $1) }
        merged.timestamp = max(self.timestamp, clock.timestamp)
        return merged
    }

    /// Partial order between two Vector clocks (ignoring the timestamp for total order)
    /// - Parameter other: The clock which should be compared
    /// - Returns: The partial order
    public func partialOrder(other: VectorClock) -> PartialOrder {
        var selfGreater = false
        var otherGreater = false
        let actors = Set(self.clocksByActors.keys).union(Set(other.clocksByActors.keys))
        for actor in actors {
            let selfValue = self.clocksByActors[actor, default: 0]
            let otherValue = other.clocksByActors[actor, default: 0]

            if selfValue > otherValue {
                selfGreater = true
            } else if otherValue > selfValue {
                otherGreater = true
            }
            if selfGreater && otherGreater {
                return .concurrent
            }
        }
        if selfGreater != otherGreater {
            return selfGreater ? .after : .before
        } else {
            return .concurrent
        }
    }
}

// MARK: - Codable

extension VectorClock: Codable {

    enum CodingKeys: String, CodingKey {
        case timestampProviderStrategy
        case clocksByActors
        case timestamp
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let timestamp = try values.decode(UnambigousTimestamp.self, forKey: .timestamp)
        let clocksByActors = try values.decode([ActorID: Int].self, forKey: .clocksByActors)
        let providerStrategy = try values.decode(TimestampProviderStrategy.self, forKey: .timestampProviderStrategy)

        self.clocksByActors = clocksByActors
        self.timestampProviderStrategy = providerStrategy
        self.timestamp = timestamp
        self.timestampProvider = providerStrategy.makeProvider(given: timestamp.timestamp)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.clocksByActors, forKey: .clocksByActors)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encode(self.timestampProviderStrategy, forKey: .timestampProviderStrategy)
    }
}

// MARK: - Hashable

extension VectorClock: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.clocksByActors)
        hasher.combine(self.timestamp)
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
        let partialOrder = lhs.partialOrder(other: rhs)
        if partialOrder == .concurrent {
            return lhs.timestamp == rhs.timestamp
        } else {
            return false
        }
    }

    public static func < (lhs: VectorClock<ActorID>, rhs: VectorClock<ActorID>) -> Bool {
        let partialOrder = lhs.partialOrder(other: rhs)
        if partialOrder == .concurrent {
            return lhs.timestamp < rhs.timestamp
        } else {
            return partialOrder == .before
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

// MARK: - Private

// MARK: - TimestampProviderStrategy

private extension VectorClock.TimestampProviderStrategy {

    func makeProvider(given start: TimeInterval = 0.0) -> () -> TimeInterval {
        switch self {
        case .unixTime:
            return { Date().timeIntervalSince1970 }
        case .monotonicIncrease:
            var current: TimeInterval = start
            return {
                current += 1.0
                return current
            }
        case .constant:
            return { start }
        }
    }
}
