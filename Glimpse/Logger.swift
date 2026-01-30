//
//  Logger.swift
//  Glimpse
//
//  Centralized logging utility for error tracking and debugging
//

import Foundation
import os.log

enum GlimpseLogger {
    private static let subsystem = "amanW.Glimpse"
    
    static let app = OSLog(subsystem: subsystem, category: "app")
    static let timer = OSLog(subsystem: subsystem, category: "timer")
    static let overlay = OSLog(subsystem: subsystem, category: "overlay")
    static let settings = OSLog(subsystem: subsystem, category: "settings")
    static let notifications = OSLog(subsystem: subsystem, category: "notifications")
    
    static func log(_ message: String, log: OSLog = .app, type: OSLogType = .default) {
        os_log("%{public}@", log: log, type: type, message)
    }
    
    static func error(_ message: String, log: OSLog = .app, error: Error? = nil) {
        if let error = error {
            os_log("%{public}@: %{public}@", log: log, type: .error, message, error.localizedDescription)
        } else {
            os_log("%{public}@", log: log, type: .error, message)
        }
    }
    
    static func debug(_ message: String, log: OSLog = .app) {
        os_log("%{public}@", log: log, type: .debug, message)
    }
}
