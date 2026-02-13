//
//  DebugLog.swift
//  Glimpse
//
//  Single-toggle debug logging for diagnosing issues.
//

import Foundation

enum DebugLog {
    /// Master switch — set to true to enable debug output
    static let enabled = false

    /// Logs a timestamped message to stdout. Includes thread info to catch
    /// unexpected background-thread execution.
    static func log(_ message: String, file: String = #file, line: Int = #line) {
        guard enabled else { return }
        let fileName = (file as NSString).lastPathComponent
        let time = Self.formatter.string(from: Date())
        let thread = Thread.isMainThread ? "main" : "bg(\(Thread.current))"
        print("[\(time)] [\(thread)] [\(fileName):\(line)] \(message)")
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()
}
