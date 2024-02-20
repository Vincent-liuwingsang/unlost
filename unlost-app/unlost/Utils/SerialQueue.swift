//
//  SerialQueue.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 25/08/2023.
//

import Foundation
import SwiftUI
import AsyncAlgorithms

//class SerialQueue {
//    static let queue = OperationQueue()
//    fileprivate static let semaphore = DispatchSemaphore(value: 1)
//    static func execute(job: SerialQueueJob) {
//        queue.addOperation(job)
//    }
//}
//
//class SerialQueueJob: Operation {
//    typealias SyncJobFinished = ()->()
//    private var callback: ((@escaping SyncJobFinished)->())!
//    
//    init(callback: @escaping ((@escaping SyncJobFinished))->()) {
//        self.callback = callback
//    }
//    
//    override func main() {
//        if self.isCancelled {
//            return
//        }
//        
//        // Waits for, or decrements, a semaphore.
//        SerialQueue.semaphore.wait()
//        
//        // Process the task in main queue
//        DispatchQueue.main.async {
//            self.callback() {
//                
//                // Once done, signal
//                DispatchQueue.main.async {
//                    // Signals (increments) a semaphore (releases for other operations).
//                    SerialQueue.semaphore.signal()
//                }
//            }
//        }
//    }
//}


typealias AsyncClosure = () async -> Void
class StartStopQueue {
    static let shared = StartStopQueue()
    let channel = AsyncChannel<AsyncClosure>()
    private var lastExecuted = Date.now
    private var task: Task<Void, Error>? = nil
    private init() {
        startCaptureEngine()
        restartIfHaulted()
    }

    private func startCaptureEngine() {
        task = Task {
            log.debug("started capture engine")
            for await task in channel {
                await task()
                lastExecuted = Date.now
            }
        }
    }
//
    private func restartIfHaulted() {
        Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [self] _ in
            if Date.now.timeIntervalSince(lastExecuted) > 20 {
                log.warning("restarting capture engine")
                task?.cancel()
                startCaptureEngine()
            } else {
                log.debug("capture engine going strong")
            }

        }
    }
}
