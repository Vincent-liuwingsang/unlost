//
//  PythonServer.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 27/06/2023.
//

import Foundation
import AppKit
import SwiftUI


struct SetDocumentPathModel : Codable {
    let path: String
}

class PythonServer: ObservableObject {
    static var shared = PythonServer()
    
    @Published var state = "dead"
    var pollTimer: Timer? = nil
    var stateTimer: Timer? = nil
    var deleteMemoryTimer: Timer? = nil
    @AppStorage("retentionPeriod") var retentionPeriod: String = defaultRetentionPeriod
    
    private init() {
        ping { [self] isRunning in
            if isRunning {
                let url = URL(string: "\(baseUrl)/kill")!

                var request = URLRequest(url: url)
                request.httpMethod = "POST"

                let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in

                    Task.detached(priority: .high) { [self] in
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                        pingPoll()
                        statePoll()
                    }
                }
                task.resume()
            } else {
                startServer()
            }
        }
    }
    
    private func pingPoll() {
        if pollTimer == nil {
            DispatchQueue.main.async { [self] in
                pollTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [self] _ in
                    ping { [self] isRunning in
                        if !isRunning {
                            startServer()
                        }
                    }
                }
            }
        }
    }
    
    private func statePoll() {
        if stateTimer == nil {
            DispatchQueue.main.async { [self] in
                stateTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [self] _ in
                    getState(
                        onComplete: { state in
                            Task { @MainActor in
                                self.state = state
                            }
                            
                        }, onError: {
                            Task { @MainActor in
                                self.state = "dead"
                            }

                        })
                }
            }
        }
    }
    
    private func deleteMemoryTask() {
        if deleteMemoryTimer == nil {
            DispatchQueue.main.async { [self] in
                deleteMemoryTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60 * 48, repeats: true) { [self] _ in
                    deleteData(retention: retentionPeriod)
                }
            }
        }
    }
    
    func ping(onResponse: ((Bool) -> Void)?) {
        var url = URL(string: "\(baseUrl)/ping")!
        let queryItems = [
            URLQueryItem(name: "client_open", value: String(NSApp?.isClientOpen() ?? false)),
        ]
        url.append(queryItems: queryItems)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
       
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                onResponse?(true)
            } else {
                onResponse?(false)
            }
        }
        task.resume()
    }
    
    func getState(onComplete: @escaping (String) -> Void, onError: @escaping() -> Void ) {
        
        var url = URL(string: "\(baseUrl)/state")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let currentTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let state = try? JSONDecoder().decode(String.self, from: data) {
                    onComplete(state)
                } else {
                    log.warning("failed to decode getState response")
                }
            } else if let error = error {
                log.warning("state query failed", context: error)
                onError()
            }
        }
        currentTask.resume()
    }
    
    func getTranscript(path: String, onComplete: @escaping ([TranscriptResponse]) -> Void ) {
        
        var url = URL(string: "\(baseUrl)/transcriptions")!
        url.append(queryItems: [
            URLQueryItem(name: "path", value: path),
        ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
    //    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let currentTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let records = try? JSONDecoder().decode([TranscriptResponse].self, from: data) {
                    onComplete(records)
                } else {
                    log.warning("failed to decode transcript response")
                }
            } else if let error = error {
                log.warning("transcript query failed", context: error)
            }
        }
        currentTask.resume()
    }
    
    func deleteMemory(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        var url = URL(string: "\(baseUrl)/memory")!
        url.append(queryItems: [
            URLQueryItem(name: "date", value: dateFormatter.string(from: date)),
        ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { _ ,_, _ in }
        task.resume()
        
    }
    
    private func startServer() {
        do {
            let workingDirectory = Bundle.main.resourceURL!.appendingPathComponent("unlost_server")
            let url = workingDirectory.appendingPathComponent("unlost_server")
            let path = getDocumentsDirectory().absoluteString.replacingOccurrences(of: "file://", with: "")
            let process = Process()
            process.currentDirectoryURL = workingDirectory
            process.executableURL = url
            process.arguments = [path]
            try process.run()
            log.debug("launched unlost_server")
        } catch let error {
            log.error("failed to launch python server \(error.localizedDescription)")
        }
    }
}
    

struct TranscriptResponse: Decodable, Identifiable, Equatable {
    static func == (lhs: TranscriptResponse, rhs: TranscriptResponse) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: String
    let text: String
    let tags: RecordResponseTags
}
