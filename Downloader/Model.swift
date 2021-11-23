//
//  Model.swift
//  Downloader
//
//  Created by Chris Eidhof on 15.11.21.
//

import Foundation

@MainActor
final class DownloadModel: NSObject, ObservableObject, Sendable {
    let url: URL
    init(_ url: URL) {
        self.url = url
    }
    
    enum State {
        case notStarted
        case started
        case inProgress(bytesWritten: Int64, bytesExpected: Int64)
        case paused(resumeData: Data?)
        case done(URL)
    }
    
    @Published var state = State.notStarted
    
    private var downloadTask: URLSessionDownloadTask?
    
    func start() async throws {
        state = .started
        let task = URLSession.shared.downloadTask(with: url)
        task.delegate = self
        task.resume()
        downloadTask = task
    }
    
    func cancel() async {
        let data = await downloadTask?.cancel()
        state = .paused(resumeData: data)
    }
}

extension URLSessionDownloadTask {
    func cancel() async -> Data? {
        await withCheckedContinuation { cont in
            self.cancel(byProducingResumeData: { data in
                cont.resume(returning: data)
            })
        }
    }
}

extension DownloadModel: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Task {
            state = .done(location)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task {
            state = .inProgress(bytesWritten: totalBytesWritten, bytesExpected: totalBytesExpectedToWrite)
        }
    }
}
