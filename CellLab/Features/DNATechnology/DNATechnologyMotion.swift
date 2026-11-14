// DNATechnologyMotion.swift
import Foundation

struct DTMotionClock {
    private var accumulated: TimeInterval = 0
    private var anchor = Date()
    private(set) var running = false
    func time(at date: Date) -> TimeInterval {
        accumulated + (running ? max(0,date.timeIntervalSince(anchor)) : 0)
    }
    mutating func setRunning(_ value: Bool) {
        let now=Date(); accumulated=time(at:now); anchor=now; running=value
    }
}
