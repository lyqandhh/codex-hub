import Foundation
import Testing
@testable import CodexHUD

struct ProcessAppServerTransportTests {
    private let chatGPTCodex = "/Applications/ChatGPT.app/Contents/Resources/codex"
    private let legacyCodex = "/Applications/Codex.app/Contents/Resources/codex"

    @Test func chatGPTBundledCodexHasHighestPriority() {
        let executablePaths = Set([chatGPTCodex, legacyCodex])

        let selected = ProcessAppServerTransport.resolveCodexExecutable {
            executablePaths.contains($0)
        }

        #expect(selected == chatGPTCodex)
    }

    @Test func legacyCodexIsUsedWhenChatGPTBundleIsUnavailable() {
        let executablePaths = Set([legacyCodex])

        let selected = ProcessAppServerTransport.resolveCodexExecutable {
            executablePaths.contains($0)
        }

        #expect(selected == legacyCodex)
    }

    @Test func pathCodexIsFinalFallbackWithoutReadingRealApplications() {
        let selected = ProcessAppServerTransport.resolveCodexExecutable { _ in false }

        #expect(selected == "codex")
    }

    @Test func stdoutEOFBeforeExitEventuallyTimesOutWithoutCrashing() {
        let timeout: TimeInterval = 0.1
        let transport = ProcessAppServerTransport(
            timeout: timeout,
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "exec 1>&-; exec /bin/sleep 5"]
        )
        let startedAt = ContinuousClock.now

        do {
            _ = try transport.exchange(requests: [], responseID: 2)
            Issue.record("Expected the exchange to time out after stdout closed")
        } catch let error as CodexAppServerError {
            #expect(error == .timedOut)
        } catch {
            Issue.record("Expected CodexAppServerError.timedOut, got \(error)")
        }

        #expect(startedAt.duration(to: .now) >= .milliseconds(50))
    }

    @Test func timeoutDoesNotWaitForProcessIgnoringSIGTERM() {
        let transport = ProcessAppServerTransport(
            timeout: 0.1,
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "trap '' TERM; exec 1>&-; exec /bin/sleep 5"]
        )
        let startedAt = ContinuousClock.now

        do {
            _ = try transport.exchange(requests: [], responseID: 2)
            Issue.record("Expected the exchange to time out")
        } catch let error as CodexAppServerError {
            #expect(error == .timedOut)
        } catch {
            Issue.record("Expected CodexAppServerError.timedOut, got \(error)")
        }

        #expect(startedAt.duration(to: .now) < .seconds(1))
    }

    @Test func timeoutDoesNotWaitForDescendantHoldingStdoutAfterLauncherExits() {
        let transport = ProcessAppServerTransport(
            timeout: 0.1,
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "(exec /bin/sleep 5) & exit 0"]
        )
        let startedAt = ContinuousClock.now

        do {
            _ = try transport.exchange(requests: [], responseID: 2)
            Issue.record("Expected the exchange to time out")
        } catch let error as CodexAppServerError {
            #expect(error == .timedOut)
        } catch {
            Issue.record("Expected CodexAppServerError.timedOut, got \(error)")
        }

        #expect(startedAt.duration(to: .now) < .seconds(1))
    }

    @Test func injectedProcessReturnsMatchingResponseUnchanged() throws {
        let response = #"{"id":2,"result":{}}"#
        let transport = ProcessAppServerTransport(
            timeout: 1,
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "printf '%s\\n' '\(response)'; exec /bin/sleep 5"]
        )
        let startedAt = ContinuousClock.now

        let received = try transport.exchange(requests: [], responseID: 2)

        #expect(received == Data(response.utf8))
        #expect(startedAt.duration(to: .now) < .seconds(1))
    }
}
