import Foundation
import Combine
import SwiftUI

class TerminalDataService: ObservableObject {
    static let shared = TerminalDataService()
    
    @Published var myPosts: [TerminalPost] = []
    @Published var circlePosts: [TerminalPost] = []
    @Published var circles: [HypeCircle] = []
    @Published var signalFeed: [TerminalSignalEvent] = []
    @Published var isLoading: Bool = false
    
    private var mockTimer: Timer?
    
    private init() {
        // Load mock data on initialization
        loadMockData()
    }
    
    deinit {
        mockTimer?.invalidate()
    }
    
    func filteredPosts(scope: TerminalScope) -> [TerminalPost] {
        let allPosts = myPosts + circlePosts
        switch scope {
        case .all:
            return allPosts
        case .circle(let circleId):
            guard let circle = circles.first(where: { $0.id == circleId }) else { return [] }
            return allPosts.filter { circle.memberIds.contains($0.creatorId) }
        }
    }
    
    func filteredSignals(scope: TerminalScope) -> [TerminalSignalEvent] {
        switch scope {
        case .all:
            return signalFeed
        case .circle(let circleId):
            guard let circle = circles.first(where: { $0.id == circleId }) else { return [] }
            // Assuming terminal events map roughly to creator handles in our mock
            // In a real app we'd filter by checking if the post's creator is in the circle.
            let handles = circle.memberIds.map { memberId -> String in
                // Mock mapping
                if memberId == "c1" { return "@alex" }
                if memberId == "c2" { return "@sam" }
                if memberId == "c3" { return "@jordan" }
                if memberId == "c4" { return "@techguru" }
                return ""
            }
            return signalFeed.filter { handles.contains($0.creatorHandle) }
        }
    }
    
    func loadMockData() {
        isLoading = true
        
        // Simulating network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.myPosts = [
                TerminalPost(id: "1", creatorId: "c1", creatorHandle: "@alex", creatorAvatarURL: nil, title: "POV: You find the best cafe", postedAt: Date().addingTimeInterval(-3600), phase: .expanding, hypeScore: 82.5, vpm: 120, acceleration: 15.2, breakoutProb: 0.78, lastEvent: .enteredExpanding),
                TerminalPost(id: "2", creatorId: "c1", creatorHandle: "@alex", creatorAvatarURL: nil, title: "Trying the new matcha", postedAt: Date().addingTimeInterval(-7200), phase: .testing, hypeScore: 45.0, vpm: 45, acceleration: 2.1, breakoutProb: 0.3, lastEvent: nil),
                TerminalPost(id: "3", creatorId: "c1", creatorHandle: "@alex", creatorAvatarURL: nil, title: "A day in my life", postedAt: Date().addingTimeInterval(-86400), phase: .plateau, hypeScore: 68.0, vpm: 12, acceleration: -5.0, breakoutProb: 0.1, lastEvent: .plateaued)
            ]
            
            self.circles = [
                HypeCircle(id: "circle1", name: "NYC Creators", memberIds: ["c1", "c2", "c3"], isInviteOnly: true, createdAt: Date().addingTimeInterval(-86400*30)),
                HypeCircle(id: "circle2", name: "Tech Tok", memberIds: ["c1", "c4"], isInviteOnly: true, createdAt: Date().addingTimeInterval(-86400*15))
            ]
            
            self.circlePosts = [
                TerminalPost(id: "10", creatorId: "c2", creatorHandle: "@sam", creatorAvatarURL: nil, title: "Hidden gems in Soho", postedAt: Date().addingTimeInterval(-1800), phase: .breakout, hypeScore: 95.0, vpm: 450, acceleration: 120.5, breakoutProb: 0.95, lastEvent: .enteredBreakout),
                TerminalPost(id: "11", creatorId: "c3", creatorHandle: "@jordan", creatorAvatarURL: nil, title: "Vintage haul", postedAt: Date().addingTimeInterval(-5400), phase: .reignite, hypeScore: 88.0, vpm: 210, acceleration: 45.0, breakoutProb: 0.85, lastEvent: .reignited),
                TerminalPost(id: "12", creatorId: "c4", creatorHandle: "@techguru", creatorAvatarURL: nil, title: "iOS 18 features", postedAt: Date().addingTimeInterval(-3600), phase: .expanding, hypeScore: 75.0, vpm: 85, acceleration: 10.0, breakoutProb: 0.65, lastEvent: .enteredExpanding)
            ]
            
            self.signalFeed = self.generateSignals(from: self.myPosts + self.circlePosts)
            self.populateMomentFeed(from: self.myPosts + self.circlePosts)
            self.isLoading = false
            
            // Start mock phase animations loop
            self.startMockPhaseTransitions()
        }
    }
    
    private func generateSignals(from posts: [TerminalPost]) -> [TerminalSignalEvent] {
        var signals: [TerminalSignalEvent] = []
        
        for post in posts {
            var eventType: TerminalEventType?
            
            if post.phase == .breakout { eventType = .enteredBreakout }
            else if post.phase == .reignite { eventType = .reignited }
            else if post.phase == .expanding { eventType = .enteredExpanding }
            else if post.phase == .plateau { eventType = .plateaued }
            else if (post.acceleration ?? 0) > 50 { eventType = .spike }
            else if (post.acceleration ?? 0) < -10 { eventType = .velocityDip }
            
            if let eventType = eventType {
                let randomOffset = Double.random(in: -3600...(-60))
                let sig = TerminalSignalEvent(id: UUID().uuidString, postId: post.id, creatorHandle: post.creatorHandle, creatorAvatarURL: post.creatorAvatarURL, eventType: eventType, timestamp: Date().addingTimeInterval(randomOffset))
                signals.append(sig)
            }
        }
        
        return signals.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Animation Mockers
    
    private func startMockPhaseTransitions() {
        mockTimer?.invalidate()
        mockTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.simulateRandomPhaseChange()
        }
    }
    
    private func simulateRandomPhaseChange() {
        guard !circlePosts.isEmpty else { return }
        let randomIndex = Int.random(in: 0..<circlePosts.count)
        var post = circlePosts[randomIndex]
        
        let possiblePhases: [DistributionPhase] = [.testing, .expanding, .breakout, .plateau, .reignite]
        let newPhase = possiblePhases.randomElement() ?? .expanding
        
        if post.phase != newPhase {
            post.phase = newPhase
            circlePosts[randomIndex] = post
            
            // Generate a feed event for this transition
            var eventType: TerminalEventType = .enteredExpanding
            if newPhase == .breakout { eventType = .enteredBreakout }
            else if newPhase == .reignite { eventType = .reignited }
            else if newPhase == .plateau { eventType = .plateaued }
            
            let newEvent = TerminalSignalEvent(id: UUID().uuidString, postId: post.id, creatorHandle: post.creatorHandle, creatorAvatarURL: post.creatorAvatarURL, eventType: eventType, timestamp: Date())
            
            withAnimation {
                signalFeed.insert(newEvent, at: 0)
            }
        }
    }
    
    // MARK: - Mock API Methods
    
    func fetchMyPosts() {}
    func fetchCirclePosts(circleId: String) {}
    func fetchCircles() {}
    
    func createCircle(name: String) {
        let newCircle = HypeCircle(id: UUID().uuidString, name: name, memberIds: ["c1"], isInviteOnly: true, createdAt: Date())
        circles.append(newCircle)
    }
    
    func inviteToCircle(circleId: String, handle: String) {}
    func acceptInvite(inviteId: String) {}
    
    // MARK: - Social Momentum Layer
    
    @Published var circleRequests: [CircleRequest] = []
    @Published var boostEvents: [BoostEvent] = []
    @Published var supportScore: CircleSupportScore = CircleSupportScore(score: 3)
    @Published var boostStreak: BoostStreak = BoostStreak(currentDays: 2, lastBoostDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()))
    @Published var momentFeed: [MomentEvent] = []
    
    // Generated from circle posts
    var circleTopMover: TerminalPost? {
        (myPosts + circlePosts).max(by: { ($0.acceleration ?? 0) < ($1.acceleration ?? 0) })
    }
    
    var circleBreakoutWatchlist: [TerminalPost] {
        (myPosts + circlePosts).filter { $0.phase == .expanding && ($0.breakoutProb ?? 0) > 0.6 }
            .sorted { ($0.breakoutProb ?? 0) > ($1.breakoutProb ?? 0) }
    }
    
    var globalSpotlight: TerminalPost? {
        (myPosts + circlePosts).filter { $0.phase == .breakout }
            .max(by: { $0.hypeScore < $1.hypeScore })
    }
    
    var globalTopMovers: [TerminalPost] {
        (myPosts + circlePosts)
            .filter { $0.phase == .breakout || ($0.phase == .expanding && ($0.breakoutProb ?? 0) > 0.75) }
            .sorted { ($0.acceleration ?? 0) > ($1.acceleration ?? 0) }
            .prefix(5).map { $0 }
    }
    
    func sendBoost(to post: TerminalPost) {
        let event = BoostEvent(
            id: UUID().uuidString,
            boostedPostId: post.id,
            boostedCreatorHandle: post.creatorHandle,
            timestamp: Date()
        )
        boostEvents.append(event)
        supportScore.score += 1
        boostStreak.currentDays = boostStreak.isActive ? boostStreak.currentDays + 1 : 1
        boostStreak.lastBoostDate = Date()
    }
    
    func sendCircleRequest(to handle: String) {
        let req = CircleRequest(
            id: UUID().uuidString,
            fromHandle: "@me",
            toHandle: handle,
            sentAt: Date(),
            isInbound: false,
            isPending: true
        )
        circleRequests.append(req)
    }
    
    func acceptCircleRequest(_ req: CircleRequest) {
        if let idx = circleRequests.firstIndex(where: { $0.id == req.id }) {
            circleRequests[idx].isPending = false
        }
    }
    
    func declineRequest(_ req: CircleRequest) {
        circleRequests.removeAll { $0.id == req.id }
    }
    
    private func populateMomentFeed(from posts: [TerminalPost]) {
        var moments: [MomentEvent] = []
        for post in posts {
            switch post.phase {
            case .breakout:
                moments.append(MomentEvent(id: UUID().uuidString, creatorHandle: post.creatorHandle, type: .enteredBreakout, timestamp: post.postedAt))
            case .reignite:
                moments.append(MomentEvent(id: UUID().uuidString, creatorHandle: post.creatorHandle, type: .reignited, timestamp: post.postedAt))
            case .expanding:
                if let vpm = post.vpm, vpm > 100 {
                    moments.append(MomentEvent(id: UUID().uuidString, creatorHandle: post.creatorHandle, type: .hitMilestone(views: 50000), timestamp: post.postedAt))
                }
            default: break
            }
        }
        momentFeed = moments.sorted { $0.timestamp > $1.timestamp }
        
        // Seed mock circle requests
        circleRequests = [
            CircleRequest(id: "r1", fromHandle: "@nova_creator", toHandle: "@me", sentAt: Date().addingTimeInterval(-3600), isInbound: true, isPending: true),
            CircleRequest(id: "r2", fromHandle: "@drift_films", toHandle: "@me", sentAt: Date().addingTimeInterval(-7200), isInbound: true, isPending: true)
        ]
    }
}

