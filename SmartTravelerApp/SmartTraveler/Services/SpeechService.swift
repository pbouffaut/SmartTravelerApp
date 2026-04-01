import Foundation
import AVFoundation
import Speech

class SpeechService: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var recognizedText = ""
    @Published var permissionGranted = false
    @Published var errorMessage: String?

    private let synthesizer = AVSpeechSynthesizer()
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Text to Speech

    func speak(_ text: String, language: String = "en") {
        synthesizer.stopSpeaking(at: .immediate)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try session.setActive(true)
        } catch {
            print("AVAudioSession playback setup error: \(error)")
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode(for: language))
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - Speech to Text

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.permissionGranted = status == .authorized
            }
        }
    }

    func startListening(language: String = "en") {
        guard permissionGranted else {
            requestPermission()
            return
        }

        stopListening()
        recognizedText = ""

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode(for: language)))
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition not available for this language"
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            audioEngine = AVAudioEngine()
            guard let audioEngine else { return }

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest else { return }

            recognitionRequest.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isListening = true

            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let result {
                        self?.recognizedText = result.bestTranscription.formattedString
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self?.stopListening()
                    }
                }
            }
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
            stopListening()
        }
    }

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Helpers

    private func languageCode(for shortCode: String) -> String {
        let mapping: [String: String] = [
            "en": "en-US", "fr": "fr-FR", "es": "es-ES", "de": "de-DE",
            "it": "it-IT", "ja": "ja-JP", "zh": "zh-CN", "ko": "ko-KR",
            "pt": "pt-BR", "ru": "ru-RU", "ar": "ar-SA", "hi": "hi-IN",
            "th": "th-TH", "vi": "vi-VN", "nl": "nl-NL", "pl": "pl-PL",
            "tr": "tr-TR", "sv": "sv-SE", "da": "da-DK", "no": "nb-NO",
            "ms": "ms-MY", "id": "id-ID",
        ]
        return mapping[shortCode] ?? shortCode
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
