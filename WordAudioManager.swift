import Foundation
import AVFoundation
import AudioToolbox
import Combine

final class WordAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var isAudioReady = false

    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
    private var currentText: String = ""

    func generateAudio(for text: String) {
        isAudioReady = false
        isPlaying = false
        currentText = text

        configureAudioSession()
        isAudioReady = true
    }

    func playAudio() {
        guard !isPlaying, isAudioReady else { return }
        isPlaying = true
        playWebTTS()
    }

    func cleanupAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isAudioReady = false

        if let audioURL = audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        audioURL = nil
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            isAudioReady = false
        }
    }

    private func playWebTTS() {
        let encodedText = currentText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedText)&tl=sv&client=tw-ob"

        guard let url = URL(string: urlString) else {
            playFallbackSound()
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if error != nil {
                    self.playFallbackSound()
                    return
                }

                guard let data, !data.isEmpty else {
                    self.playFallbackSound()
                    return
                }

                let filename = "word_tts_\(UUID().uuidString).mp3"
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioURL = documentsPath.appendingPathComponent(filename)

                do {
                    try data.write(to: audioURL)
                    self.audioURL = audioURL
                    self.audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                } catch {
                    self.playFallbackSound()
                }
            }
        }.resume()
    }

    private func playFallbackSound() {
        AudioServicesPlaySystemSound(1005)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isPlaying = false
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
