//
//  MessagesTests.swift
//  GlimpseTests
//
//  Tests for break reminder messages.
//

import Testing
@testable import Glimpse

struct MessagesTests {

    @Test func standardMessagesCountIsExpected() {
        #expect(Messages.standard.count == 45)
    }

    @Test func rareMessagesCountIsExpected() {
        #expect(Messages.rare.count == 15)
    }

    @Test func exercisesMessagesCountIsExpected() {
        #expect(Messages.exercises.count == 20)
    }

    @Test func postureMessagesCountIsExpected() {
        #expect(Messages.posture.count == 20)
    }

    @Test func breathingMessagesCountIsExpected() {
        #expect(Messages.breathing.count == 20)
    }

    @Test func walkMessagesCountIsExpected() {
        #expect(Messages.walk.count == 20)
    }

    @Test func randomReturnsNonEmptyString() {
        let message = Messages.random()
        #expect(!message.isEmpty)
    }

    @Test func randomReturnsValidMessage() {
        let allMessages = Messages.standard + Messages.rare + Messages.exercises + Messages.posture + Messages.breathing + Messages.walk
        // Run multiple times to increase confidence
        for _ in 0..<100 {
            let message = Messages.random()
            #expect(allMessages.contains(message))
        }
    }

    @Test func nextCyclesThroughAllCategories() {
        let allMessages = Messages.standard + Messages.rare + Messages.exercises + Messages.posture + Messages.breathing + Messages.walk
        // Call next() 12 times (two full cycles) — every message must be valid
        for _ in 0..<12 {
            let message = Messages.next()
            #expect(allMessages.contains(message))
            #expect(!message.isEmpty)
        }
    }

    @Test func standardMessagesAreUnique() {
        let uniqueMessages = Set(Messages.standard)
        #expect(uniqueMessages.count == Messages.standard.count)
    }

    @Test func rareMessagesAreUnique() {
        let uniqueMessages = Set(Messages.rare)
        #expect(uniqueMessages.count == Messages.rare.count)
    }

    @Test func exercisesMessagesAreUnique() {
        let uniqueMessages = Set(Messages.exercises)
        #expect(uniqueMessages.count == Messages.exercises.count)
    }

    @Test func postureMessagesAreUnique() {
        let uniqueMessages = Set(Messages.posture)
        #expect(uniqueMessages.count == Messages.posture.count)
    }

    @Test func breathingMessagesAreUnique() {
        let uniqueMessages = Set(Messages.breathing)
        #expect(uniqueMessages.count == Messages.breathing.count)
    }

    @Test func walkMessagesAreUnique() {
        let uniqueMessages = Set(Messages.walk)
        #expect(uniqueMessages.count == Messages.walk.count)
    }

    @Test func allMessagesAreNonEmpty() {
        let allMessages = Messages.standard + Messages.rare + Messages.exercises + Messages.posture + Messages.breathing + Messages.walk
        for message in allMessages {
            #expect(!message.isEmpty)
        }
    }
}
