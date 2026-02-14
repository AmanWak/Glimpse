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

    @Test func randomReturnsNonEmptyString() {
        let message = Messages.random()
        #expect(!message.isEmpty)
    }

    @Test func randomReturnsValidMessage() {
        // Run multiple times to increase confidence
        for _ in 0..<100 {
            let message = Messages.random()
            let isStandard = Messages.standard.contains(message)
            let isRare = Messages.rare.contains(message)
            #expect(isStandard || isRare)
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

    @Test func allMessagesAreNonEmpty() {
        for message in Messages.standard {
            #expect(!message.isEmpty)
        }
        for message in Messages.rare {
            #expect(!message.isEmpty)
        }
    }
}
