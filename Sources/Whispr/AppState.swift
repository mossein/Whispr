import Foundation
import SwiftUI

@Observable
final class AppState {
    var isRecording = false
    var isModelLoaded = false
    var isModelLoading = false
    var modelLoadProgress: String = "Loading model..."
    var audioLevels: [CGFloat] = Array(repeating: 0, count: 30)
    var transcribedText: String = ""
    var lastError: String?

    static let shared = AppState()
    private init() {}
}
