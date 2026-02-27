import Foundation

// MARK: - Scope

enum TerminalScope: Equatable {
    case all
    case circle(HypeCircle.ID)
}

// MARK: - Posts & Events

struct TerminalPost: Identifiable, Codable {
    var id: String
    var creatorId: String
    var creatorHandle: String
    var creatorAvatarURL: URL?
    var title: String?
    var postedAt: Date
    var phase: DistributionPhase
    var hypeScore: Double       // 0..100
    var vpm: Double?
    var acceleration: Double?
    var breakoutProb: Double?
    var lastEvent: TerminalEventType?
}

enum TerminalEventType: String, Codable {
    case enteredExpanding = "entered_expanding"
    case enteredBreakout = "entered_breakout"
    case plateaued = "plateaued"
    case reignited = "reignited"
    case velocityDip = "velocity_dip"
    case spike = "spike"
    
    var signalDescription: String {
        switch self {
        case .enteredExpanding: return "entered EXPANDING phase"
        case .enteredBreakout: return "entered BREAKOUT phase"
        case .plateaued: return "momentum PLATEAUED"
        case .reignited: return "RE-IGNITED"
        case .velocityDip: return "velocity DIPPED"
        case .spike: return "velocity SPIKE"
        }
    }
}

struct TerminalSignalEvent: Identifiable, Codable {
    var id: String
    var postId: String
    var creatorHandle: String
    var creatorAvatarURL: URL?
    var eventType: TerminalEventType
    var timestamp: Date
}

// MARK: - Circle System

struct HypeCircle: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var memberIds: [String]
    var isInviteOnly: Bool
    var createdAt: Date
}

struct CircleMember: Identifiable, Codable, Hashable {
    var id: String
    var handle: String
    var avatarURL: URL?
    var isConnected: Bool
    var overallScore: Double?
    var trend7d: Double?
}

// MARK: - Social Momentum Layer

struct CircleRequest: Identifiable, Codable {
    var id: String
    var fromHandle: String
    var toHandle: String
    var sentAt: Date
    var isInbound: Bool
    var isPending: Bool
}

struct BoostEvent: Identifiable, Codable {
    var id: String
    var boostedPostId: String
    var boostedCreatorHandle: String
    var timestamp: Date
}

struct CircleSupportScore {
    var score: Int
    
    var rankLabel: String {
        switch score {
        case 0..<5:   return "New"
        case 5..<20:  return "Supporter"
        case 20..<50: return "Champion"
        default:      return "Legend"
        }
    }
}

struct BoostStreak {
    var currentDays: Int
    var lastBoostDate: Date?
    
    var isActive: Bool {
        guard let last = lastBoostDate else { return false }
        return Calendar.current.isDateInToday(last) || Calendar.current.isDateInYesterday(last)
    }
}

struct MomentEvent: Identifiable {
    var id: String
    var creatorHandle: String
    var type: MomentType
    var timestamp: Date
    
    enum MomentType {
        case enteredBreakout
        case hitMilestone(views: Int)
        case reignited
        
        var emoji: String {
            switch self {
            case .enteredBreakout:    return "🚀"
            case .hitMilestone:       return "🔥"
            case .reignited:          return "⚡"
            }
        }
        
        var label: String {
            switch self {
            case .enteredBreakout:        return "entered Breakout"
            case .hitMilestone(let v):    return "hit \(NumberFormatterUtils.formatCompact(number: v)) views"
            case .reignited:              return "reignited after plateau"
            }
        }
    }
}
