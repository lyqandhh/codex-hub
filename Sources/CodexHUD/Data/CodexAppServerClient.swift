import Foundation

protocol AppServerTransport: Sendable {
    func exchange(requests: [Data], responseID: Int) throws -> Data
}

enum CodexAppServerError: Error, Equatable {
    case codexNotFound
    case launchFailed
    case timedOut
    case invalidResponse
    case serverError(String)
}

struct CodexAppServerClient: Sendable {
    private let transport: any AppServerTransport

    init(transport: any AppServerTransport = ProcessAppServerTransport()) {
        self.transport = transport
    }

    func requestRateLimits() async throws -> Data {
        let requests = [
            try Self.request(
                id: 1,
                method: "initialize",
                params: [
                    "clientInfo": ["name": "codex-hud", "version": "1.0"],
                    "capabilities": NSNull()
                ]
            ),
            try Self.request(id: 2, method: "account/rateLimits/read", params: [:])
        ]

        let response = try await Task.detached {
            try transport.exchange(requests: requests, responseID: 2)
        }.value

        guard let object = try? JSONSerialization.jsonObject(with: response) as? [String: Any],
              (object["id"] as? NSNumber)?.intValue == 2,
              object["result"] != nil else {
            throw CodexAppServerError.invalidResponse
        }
        if let error = object["error"] as? [String: Any] {
            throw CodexAppServerError.serverError(error["message"] as? String ?? "unknown")
        }
        return response
    }

    private static func request(id: Int, method: String, params: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["id": id, "method": method, "params": params])
    }
}

struct ProcessAppServerTransport: AppServerTransport {
    var timeout: TimeInterval = 8

    func exchange(requests: [Data], responseID: Int) throws -> Data {
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        let codexPath = "/Applications/Codex.app/Contents/Resources/codex"

        if FileManager.default.isExecutableFile(atPath: codexPath) {
            process.executableURL = URL(fileURLWithPath: codexPath)
            process.arguments = ["app-server", "--stdio"]
        } else if FileManager.default.isExecutableFile(atPath: "/usr/bin/env") {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["codex", "app-server", "--stdio"]
        } else {
            throw CodexAppServerError.codexNotFound
        }

        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do { try process.run() } catch { throw CodexAppServerError.launchFailed }

        for request in requests {
            input.fileHandleForWriting.write(request)
            input.fileHandleForWriting.write(Data([0x0A]))
        }

        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + timeout)
        timer.setEventHandler { [process] in
            if process.isRunning { process.terminate() }
        }
        timer.resume()
        defer {
            timer.cancel()
            try? input.fileHandleForWriting.close()
            try? output.fileHandleForReading.close()
            if process.isRunning { process.terminate() }
        }

        var buffer = Data()
        while process.isRunning {
            let chunk = output.fileHandleForReading.availableData
            if chunk.isEmpty { break }
            buffer.append(chunk)

            while let newline = buffer.firstIndex(of: 0x0A) {
                let line = Data(buffer[..<newline])
                buffer.removeSubrange(...newline)
                if Self.responseID(in: line) == responseID { return line }
            }
        }

        throw process.terminationReason == .uncaughtSignal
            ? CodexAppServerError.timedOut
            : CodexAppServerError.invalidResponse
    }

    private static func responseID(in data: Data) -> Int? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return (object["id"] as? NSNumber)?.intValue
    }
}
