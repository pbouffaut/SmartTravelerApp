import SwiftUI

struct TranslatorView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var translationService = TranslationService()
    @StateObject private var speechService = SpeechService()

    @State private var inputText = ""
    @State private var sourceLang = "en"
    @State private var targetLang = "fr"
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ST.Spacing.l) {
                    // Language selector
                    languageSelector

                    // Input area
                    inputCard

                    // Output area
                    outputCard

                    // Provider info
                    providerInfo
                }
                .padding(.horizontal, ST.Spacing.m)
                .padding(.top, ST.Spacing.s)
            }
            .screenBackground()
            .navigationTitle("Translate")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(ST.Colors.accent)
                    }
                }
            }
            .onAppear {
                speechService.requestPermission()
                targetLang = settings.homeLanguage
            }
            .sheet(isPresented: $showSourcePicker) {
                languagePickerSheet(selection: $sourceLang, title: "Source Language")
            }
            .sheet(isPresented: $showTargetPicker) {
                languagePickerSheet(selection: $targetLang, title: "Target Language")
            }
        }
    }

    // MARK: - Components

    private var languageSelector: some View {
        HStack(spacing: ST.Spacing.s) {
            Button(action: { showSourcePicker = true }) {
                languagePill(code: sourceLang)
            }

            Button(action: {
                let temp = sourceLang
                sourceLang = targetLang
                targetLang = temp
                if !translationService.translatedText.isEmpty {
                    inputText = translationService.translatedText
                    translationService.translatedText = ""
                }
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ST.Colors.accent)
                    .frame(width: 36, height: 36)
                    .background(ST.Colors.accentTint)
                    .cornerRadius(18)
            }

            Button(action: { showTargetPicker = true }) {
                languagePill(code: targetLang)
            }
        }
    }

    private func languagePill(code: String) -> some View {
        let lang = TranslationService.supportedLanguages.first { $0.code == code }
        return HStack(spacing: 6) {
            Text(lang?.flag ?? "")
                .font(.system(size: 16))
            Text(lang?.name ?? code)
                .font(ST.Font.caption())
                .foregroundColor(ST.Colors.textPrimary)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(ST.Colors.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(ST.Colors.card)
        .cornerRadius(ST.Radius.button)
        .overlay(
            RoundedRectangle(cornerRadius: ST.Radius.button)
                .stroke(ST.Colors.border, lineWidth: 0.5)
        )
    }

    private var inputCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: ST.Spacing.s) {
                SectionHeader("Input", icon: "text.cursor")

                ZStack(alignment: .topLeading) {
                    if inputText.isEmpty {
                        Text("Type or speak something...")
                            .font(ST.Font.body())
                            .foregroundColor(ST.Colors.textTertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }

                    TextEditor(text: $inputText)
                        .font(ST.Font.body())
                        .foregroundColor(ST.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80)
                }

                HStack(spacing: ST.Spacing.s) {
                    // Microphone button
                    Button(action: {
                        if speechService.isListening {
                            speechService.stopListening()
                            inputText = speechService.recognizedText
                        } else {
                            speechService.startListening(language: sourceLang)
                        }
                    }) {
                        Image(systemName: speechService.isListening ? "mic.fill" : "mic")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(speechService.isListening ? .white : ST.Colors.accent)
                            .frame(width: 38, height: 38)
                            .background(speechService.isListening ? ST.Colors.danger : ST.Colors.accentTint)
                            .cornerRadius(19)
                    }

                    // Listen to input
                    Button(action: {
                        speechService.speak(inputText, language: sourceLang)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ST.Colors.textSecondary)
                            .frame(width: 38, height: 38)
                            .background(ST.Colors.surface)
                            .cornerRadius(19)
                    }
                    .disabled(inputText.isEmpty)

                    Spacer()

                    // Clear
                    if !inputText.isEmpty {
                        Button(action: {
                            inputText = ""
                            translationService.translatedText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(ST.Colors.textTertiary)
                        }
                    }

                    // Translate button
                    AccentButton("Translate", icon: "arrow.right") {
                        Task {
                            await translationService.translate(
                                text: inputText,
                                from: sourceLang,
                                to: targetLang,
                                provider: settings.translationProvider,
                                apiKey: settings.translationAPIKey
                            )
                        }
                    }
                }

                // Listening indicator
                if speechService.isListening {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ST.Colors.danger)
                            .frame(width: 6, height: 6)
                        Text("Listening...")
                            .font(ST.Font.label())
                            .foregroundColor(ST.Colors.danger)
                    }

                    if !speechService.recognizedText.isEmpty {
                        Text(speechService.recognizedText)
                            .font(ST.Font.caption())
                            .foregroundColor(ST.Colors.textSecondary)
                            .italic()
                    }
                }
            }
        }
    }

    private var outputCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: ST.Spacing.s) {
                HStack {
                    SectionHeader("Translation", icon: "text.bubble")
                    Spacer()
                    if translationService.isTranslating {
                        ProgressView()
                            .tint(ST.Colors.accent)
                            .scaleEffect(0.8)
                    }
                }

                if let error = translationService.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(ST.Colors.danger)
                        Text(error)
                            .font(ST.Font.caption())
                            .foregroundColor(ST.Colors.danger)
                    }
                    .padding(12)
                    .background(ST.Colors.dangerTint)
                    .cornerRadius(ST.Radius.input)
                } else if translationService.translatedText.isEmpty {
                    Text("Translation will appear here")
                        .font(ST.Font.body())
                        .foregroundColor(ST.Colors.textTertiary)
                        .frame(minHeight: 60)
                } else {
                    Text(translationService.translatedText)
                        .font(ST.Font.body(17))
                        .foregroundColor(ST.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)

                    HStack(spacing: ST.Spacing.s) {
                        Button(action: {
                            speechService.speak(translationService.translatedText, language: targetLang)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: speechService.isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 13))
                                Text(speechService.isSpeaking ? "Stop" : "Listen")
                                    .font(ST.Font.label())
                            }
                            .foregroundColor(ST.Colors.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(ST.Colors.accentTint)
                            .cornerRadius(ST.Radius.pill)
                        }

                        Button(action: {
                            UIPasteboard.general.string = translationService.translatedText
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 13))
                                Text("Copy")
                                    .font(ST.Font.label())
                            }
                            .foregroundColor(ST.Colors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(ST.Colors.surface)
                            .cornerRadius(ST.Radius.pill)
                        }
                    }
                }
            }
        }
    }

    private var providerInfo: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
            Text("Using \(settings.translationProvider.displayName)")
                .font(ST.Font.label())
            if settings.translationProvider.requiresKey && settings.translationAPIKey.isEmpty {
                Text("(no key set)")
                    .font(ST.Font.label())
                    .foregroundColor(ST.Colors.danger)
            }
        }
        .foregroundColor(ST.Colors.textTertiary)
    }

    // MARK: - Language Picker Sheet

    private func languagePickerSheet(selection: Binding<String>, title: String) -> some View {
        NavigationStack {
            List {
                ForEach(TranslationService.supportedLanguages, id: \.code) { lang in
                    Button(action: {
                        selection.wrappedValue = lang.code
                        showSourcePicker = false
                        showTargetPicker = false
                    }) {
                        HStack(spacing: 12) {
                            Text(lang.flag)
                                .font(.system(size: 20))
                            Text(lang.name)
                                .font(ST.Font.body())
                                .foregroundColor(ST.Colors.textPrimary)
                            Spacer()
                            if selection.wrappedValue == lang.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ST.Colors.accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(ST.Colors.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ST.Colors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showSourcePicker = false
                        showTargetPicker = false
                    }
                    .foregroundColor(ST.Colors.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
