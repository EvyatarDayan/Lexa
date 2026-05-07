import Foundation
import Combine
import Speech
import AVFoundation

final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""

    private var currentCompletion: ((String) -> Void)?
    private var onRecordingStopped: (() -> Void)?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startRecording(language: String, completion: @escaping (String) -> Void) {
        if isRecording {
            stopRecording()
            return
        }

        currentCompletion = completion

        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.startSimpleRecording(language: language)
                case .denied, .restricted, .notDetermined:
                    self?.stopRecording()
                @unknown default:
                    self?.stopRecording()
                }
            }
        }
    }

    private func startSimpleRecording(language: String) {
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language)) else {
            stopRecording()
            return
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true

        let recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self?.transcribedText = text
                    self?.currentCompletion?(text)
                }

                if result.isFinal {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.stopRecording()
                    }
                }
            }

            if error != nil {
                self?.stopRecording()
            }
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            self.audioEngine = audioEngine
            self.recognitionRequest = recognitionRequest
            self.recognitionTask = recognitionTask

            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            stopRecording()
        }
    }

    func stopRecording() {
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        currentCompletion = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // No-op: failing to deactivate does not block app usage.
        }

        DispatchQueue.main.async {
            self.isRecording = false
            self.onRecordingStopped?()
        }
    }

    func setOnRecordingStopped(_ callback: @escaping () -> Void) {
        onRecordingStopped = callback
    }
}
