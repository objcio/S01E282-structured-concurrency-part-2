//
//  ContentView.swift
//  Downloader
//
//  Created by Chris Eidhof on 15.11.21.
//

import SwiftUI

let urls = [
    URL(string: "https://www.objc.io/index.html")!,
    URL(string: "http://ftp.acc.umu.se/mirror/wikimedia.org/dumps/enwiki/20211101/enwiki-20211101-abstract.xml.gz")!
]

struct DownloadView: View {
    @ObservedObject var model: DownloadModel
    
    var body: some View {
        VStack {
            Text("\(model.url)")
            switch model.state {
            case .notStarted:
                Button("Start") {
                    Task { [model] in
                        try await model.start()
                    }
                }
            case .started:
                ProgressView()
                    .progressViewStyle(.linear)
            case .paused(resumeData: _):
                Text("Paused...")
            case let .inProgress(bytesWritten, bytesExpected):
                HStack {
                    ProgressView("Progress", value: Double(bytesWritten), total: Double(bytesExpected))
                        .progressViewStyle(.linear)
                    Button("Cancel") {
                        Task { [model] in
                            await model.cancel()
                        }
                    }
                }
            case let .done(url):
                Text("Done: \(url)")
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            ForEach(urls, id: \.self) { url in
                DownloadView(model: DownloadModel(url))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
