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
}
