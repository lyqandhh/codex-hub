import Testing
@testable import CodexHUD

struct HUDLayoutTests {
    @Test func windowMatchesApprovedDesignAspectRatio() {
        #expect(HUDLayout.windowWidth == 118)
        #expect(HUDLayout.windowHeight == 46)
        #expect(abs(HUDLayout.windowWidth / HUDLayout.windowHeight - 2.565) < 0.01)
    }

    @Test func ringKeepsDesignBreathingRoom() {
        #expect(HUDLayout.ringDiameter == 32)
        #expect(HUDLayout.ringDiameter / HUDLayout.windowHeight < 0.71)
    }
}
