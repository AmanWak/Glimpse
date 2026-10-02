//
//  GlimpseUITests.swift
//  GlimpseUITests
//
//  Intentionally contains no tests — see below.
//

// Glimpse is an LSUIElement agent app: no Dock icon, no windows of its own, and its only
// persistent UI is a MenuBarExtra. XCUIApplication cannot drive or terminate it — the
// generated `testExample`/`testLaunchPerformance` boilerplate that used to live here
// failed on every run ("Failed to terminate amanW.Glimpse"), burning 60s per attempt and
// making `xcodebuild test` permanently red. A gate that always fails gets ignored, which
// is worse than no gate.
//
// Launch smoke coverage lives in GlimpseUITestsLaunchTests.swift, which does pass.
// Everything else is covered by the Swift Testing unit suite in GlimpseTests/.
//
// If UI automation is ever needed here, it has to go through the menu bar item via the
// system-wide accessibility hierarchy, not XCUIApplication(bundleIdentifier:).
