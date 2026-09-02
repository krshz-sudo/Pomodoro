import AudioToolbox

/// Plays a short completion chime using `AudioServicesPlaySystemSound`, which
/// (unlike AVAudioPlayer configured for background playback) automatically
/// respects the device's silent-mode ringer switch — matching the spec's
/// "sound on completion, respecting silent mode toggle in settings."
final class AudioFeedbackPlayer {
    static let shared = AudioFeedbackPlayer()

    private var completionSoundID: SystemSoundID = 1054 // system "Tweet Sent" style chime

    private init() {}

    func playCompletionSound() {
        AudioServicesPlaySystemSound(completionSoundID)
    }
}
