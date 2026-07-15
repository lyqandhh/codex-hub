import Darwin
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
    private let timeout: TimeInterval
    private let executableURL: URL?
    private let arguments: [String]?

    init(
        timeout: TimeInterval = 8,
        executableURL: URL? = nil,
        arguments: [String]? = nil
    ) {
        self.timeout = timeout
        self.executableURL = executableURL
        self.arguments = arguments
    }

    static func resolveCodexExecutable(
        isExecutableFile: (String) -> Bool
    ) -> String {
        let bundledCandidates = [
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/Applications/Codex.app/Contents/Resources/codex"
        ]
        return bundledCandidates.first(where: isExecutableFile) ?? "codex"
    }

    func exchange(requests: [Data], responseID: Int) throws -> Data {
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        let appServerArguments = arguments ?? ["app-server", "--stdio"]

        if let executableURL {
            process.executableURL = executableURL
            process.arguments = appServerArguments
        } else {
            let codexExecutable = Self.resolveCodexExecutable(
                isExecutableFile: FileManager.default.isExecutableFile(atPath:)
            )

            if codexExecutable.hasPrefix("/") {
                process.executableURL = URL(fileURLWithPath: codexExecutable)
                process.arguments = appServerArguments
            } else if FileManager.default.isExecutableFile(atPath: "/usr/bin/env") {
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = [codexExecutable] + appServerArguments
            } else {
                throw CodexAppServerError.codexNotFound
            }
        }

        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do { try process.run() } catch { throw CodexAppServerError.launchFailed }
        let launchedPID = process.processIdentifier
        let deadline = ContinuousClock.now.advanced(by: .seconds(timeout))

        for request in requests {
            input.fileHandleForWriting.write(request)
            input.fileHandleForWriting.write(Data([0x0A]))
        }

        defer {
            try? input.fileHandleForWriting.close()
            try? output.fileHandleForReading.close()
            if process.isRunning, process.processIdentifier == launchedPID {
                _ = Darwin.kill(launchedPID, SIGTERM)
            }
        }

        let outputDescriptor = output.fileHandleForReading.fileDescriptor
        var readBuffer = [UInt8](repeating: 0, count: 4_096)
        var buffer = Data()
        while true {
            guard let pollTimeout = Self.pollTimeout(until: deadline) else {
                Self.terminateAfterTimeout(process, launchedPID: launchedPID)
                throw CodexAppServerError.timedOut
            }

            var descriptor = pollfd(
                fd: outputDescriptor,
                events: Int16(POLLIN | POLLHUP | POLLERR),
                revents: 0
            )
            let pollResult = Darwin.poll(&descriptor, 1, pollTimeout)
            if pollResult == 0 {
                Self.terminateAfterTimeout(process, launchedPID: launchedPID)
                throw CodexAppServerError.timedOut
            }
            if pollResult < 0 {
                if errno == EINTR { continue }
                throw CodexAppServerError.invalidResponse
            }
            guard Self.pollTimeout(until: deadline) != nil else {
                Self.terminateAfterTimeout(process, launchedPID: launchedPID)
                throw CodexAppServerError.timedOut
            }

            if descriptor.revents & Int16(POLLNVAL) != 0 {
                throw CodexAppServerError.invalidResponse
            }
            guard descriptor.revents & Int16(POLLIN | POLLHUP) != 0 else {
                throw CodexAppServerError.invalidResponse
            }

            let bytesRead = readBuffer.withUnsafeMutableBytes { bytes in
                Darwin.read(outputDescriptor, bytes.baseAddress, bytes.count)
            }
            if bytesRead < 0 {
                if errno == EINTR || errno == EAGAIN { continue }
                throw CodexAppServerError.invalidResponse
            }
            if bytesRead == 0 {
                guard Self.waitForExit(process, until: deadline) else {
                    Self.terminateAfterTimeout(process, launchedPID: launchedPID)
                    throw CodexAppServerError.timedOut
                }
                process.waitUntilExit()
                throw process.terminationReason == .uncaughtSignal
                    ? CodexAppServerError.timedOut
                    : CodexAppServerError.invalidResponse
            }
            buffer.append(contentsOf: readBuffer.prefix(Int(bytesRead)))

            while let newline = buffer.firstIndex(of: 0x0A) {
                let line = Data(buffer[..<newline])
                buffer.removeSubrange(...newline)
                if Self.responseID(in: line) == responseID { return line }
            }
        }
    }

    private static func pollTimeout(until deadline: ContinuousClock.Instant) -> Int32? {
        let remaining = ContinuousClock.now.duration(to: deadline)
        guard remaining > .zero else { return nil }

        let components = remaining.components
        let wholeMilliseconds = components.seconds * 1_000
        let fractionalMilliseconds = components.attoseconds / 1_000_000_000_000_000
            + (components.attoseconds % 1_000_000_000_000_000 == 0 ? 0 : 1)
        let milliseconds = wholeMilliseconds + fractionalMilliseconds
        return Int32(min(milliseconds, Int64(Int32.max)))
    }

    private static func waitForExit(
        _ process: Process,
        until deadline: ContinuousClock.Instant
    ) -> Bool {
        while process.isRunning {
            guard let remaining = pollTimeout(until: deadline) else { return false }
            _ = Darwin.poll(nil, 0, min(remaining, 10))
        }
        return true
    }

    private static func terminateAfterTimeout(_ process: Process, launchedPID: pid_t) {
        guard process.isRunning, process.processIdentifier == launchedPID else { return }
        let terminateResult = Darwin.kill(launchedPID, SIGTERM)
        guard terminateResult == 0 else { return }

        let forceTerminationDeadline = ContinuousClock.now.advanced(by: .milliseconds(250))
        if waitForExit(process, until: forceTerminationDeadline) {
            process.waitUntilExit()
            return
        }
        guard process.isRunning, process.processIdentifier == launchedPID else {
            process.waitUntilExit()
            return
        }

        let killResult = Darwin.kill(launchedPID, SIGKILL)
        guard killResult == 0 else { return }

        let reapDeadline = ContinuousClock.now.advanced(by: .milliseconds(250))
        if waitForExit(process, until: reapDeadline) {
            process.waitUntilExit()
        }
    }

    private static func responseID(in data: Data) -> Int? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return (object["id"] as? NSNumber)?.intValue
    }
}
