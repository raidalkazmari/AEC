import SwiftUI
import Foundation
import PhotosUI
import Security
import AVFoundation
import UIKit

struct ChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
}

struct AIView: View {
    @EnvironmentObject private var store: AppStore
    @State private var messages: [ChatMessage] = []
    @State private var prompt = ""
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var previousResponseID: String?
    @State private var photoLibraryVisible = false
    @State private var imageData: Data?

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                messagesView
                composer
            }
        }
        .navigationTitle(store.t("المساعد الذكي", "AI assistant"))
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { NavigationLink(destination: SettingsView()) { Image(systemName: "gearshape.fill") } } }
        .sheet(isPresented: $photoLibraryVisible) {
            PhotoLibraryPicker { image in
                imageData = image.jpegData(compressionQuality: 0.82)
            }
        }
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty { emptyState }
                    ForEach(messages) { message in
                        HStack {
                            if message.role == .user { Spacer(minLength: 40) }
                            Text(message.text)
                                .padding(13)
                                .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(message.role == .user ? AppTheme.teal : Color(.secondarySystemBackground)))
                                .foregroundColor(message.role == .user ? .white : .primary)
                            if message.role == .assistant { Spacer(minLength: 40) }
                        }
                        .id(message.id)
                    }
                    if isLoading { HStack { ProgressView(); Text(store.t("يفكر…", "Thinking…")).font(.caption).foregroundColor(.secondary); Spacer() } }
                    if let errorText { Text(errorText).font(.caption).foregroundColor(.red).frame(maxWidth: .infinity, alignment: .leading) }
                }.padding()
            }
            .keyboardDismissOnTapAndDrag()
            .onChange(of: messages.count) { _ in if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } } }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(LinearGradient(colors: [AppTheme.teal.opacity(0.18), AppTheme.gold.opacity(0.18)], startPoint: .top, endPoint: .bottom)).frame(width: 92, height: 92)
                Image(systemName: "sparkles").font(.system(size: 38)).foregroundColor(AppTheme.primary)
            }
            Text(store.t("اكتب أي شيء", "Ask anything")).font(.title2.bold()).multilineTextAlignment(.center)
            Text(store.t("محادثة حرة بأسلوب Gemini، مع إمكانية إرفاق صورة عند الحاجة.", "A free-form Gemini-style conversation with optional images."))
                .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding(.top, 60)
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if imageData != nil {
                HStack { Label(store.t("صورة مرفقة", "Image attached"), systemImage: "photo.fill"); Spacer(); Button { imageData = nil } label: { Image(systemName: "xmark.circle.fill") } }
                    .font(.caption).padding(.horizontal)
            }
            HStack(alignment: .bottom, spacing: 9) {
                Button { UIApplication.shared.dismissKeyboard(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { photoLibraryVisible = true } } label: { Image(systemName: "photo.fill").font(.title3).frame(width: 36, height: 36) }
                TextField(store.t("اكتب أي شيء…", "Ask anything…"), text: $prompt)
                    .lineLimit(5).padding(.horizontal, 12).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.tertiarySystemBackground)))
                Button { send() } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 35)).foregroundColor(AppTheme.teal) }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }.padding(.horizontal).padding(.bottom, 9)
        }.background(Color(.secondarySystemBackground))
    }

    private func send() {
        let clean = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        UIApplication.shared.dismissKeyboard()
        let keyName = store.settings.aiProvider == .gemini ? "gemini-api-key" : "openai-api-key"
        guard let key = KeychainService.load(key: keyName), !key.isEmpty else {
            errorText = store.settings.aiProvider == .gemini ? store.t("أضف مفتاح Gemini المجاني من الإعدادات أولًا.", "Add your free Gemini key in Settings first.") : store.t("أضف مفتاح OpenAI API من الإعدادات أولًا.", "Add an OpenAI API key in Settings first.")
            return
        }
        messages.append(ChatMessage(role: .user, text: clean)); prompt = ""; errorText = nil; isLoading = true
        let conversation = messages
        let sentImage = imageData; imageData = nil
        Task {
            do {
                let result = try await AIService.send(
                    text: clean,
                    imageData: sentImage,
                    context: assistantContext,
                    history: conversation,
                    apiKey: key,
                    provider: store.settings.aiProvider,
                    model: store.settings.aiProvider == .gemini ? store.settings.geminiModel : store.settings.aiModel,
                    previousResponseID: previousResponseID,
                    webSearchEnabled: false
                )
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, text: result.text))
                    previousResponseID = result.id
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private var assistantContext: String {
        let current = store.courses.filter { $0.status == .current }.map { "\($0.code) \($0.nameAR)" }.joined(separator: "، ")
        return """
        أنت مساعد ذكي عام داخل تطبيق طلاب AEC. تعامل كمحادثة حرة: أجب عن أي موضوع يكتبه المستخدم، بالعربية افتراضيًا أو باللغة التي يطلبها، وبأسلوب طبيعي مباشر من دون قوالب أو زخرفة زائدة. لا تحصر الإجابات بالدراسة.
        استخدم سياق الطالب التالي فقط عندما يكون مفيدًا للسؤال: التخصص \(store.profile.major)، الخطة \(store.profile.planHours) ساعة، المجتاز \(store.profile.completedHours)، الحالي \(store.profile.currentHours)، المتبقي \(store.profile.officialRemainingHours)، المعدل \(store.profile.gpa)، والمواد الحالية: \(current).
        لا تدّعِ تنفيذ إجراء خارجي أو الوصول للبوابة ما لم يحدث فعليًا.
        """
    }
}

enum AIService {
    struct Result { let text: String; let id: String? }

    static func send(text: String, imageData: Data?, context: String, history: [ChatMessage], apiKey: String, provider: AIProvider, model: String, previousResponseID: String?, webSearchEnabled: Bool) async throws -> Result {
        switch provider {
        case .gemini:
            return try await sendGemini(text: text, imageData: imageData, context: context, history: history, apiKey: apiKey, model: model)
        case .openAI:
            return try await sendOpenAI(text: text, imageData: imageData, context: context, apiKey: apiKey, model: model, previousResponseID: previousResponseID, webSearchEnabled: webSearchEnabled)
        }
    }

    private static func sendOpenAI(text: String, imageData: Data?, context: String, apiKey: String, model: String, previousResponseID: String?, webSearchEnabled: Bool) async throws -> Result {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else { throw AIError.invalidResponse }
        var content: [[String: Any]] = [["type": "input_text", "text": text]]
        if let imageData {
            content.append(["type": "input_image", "image_url": "data:image/jpeg;base64,\(imageData.base64EncodedString())"])
        }
        var body: [String: Any] = [
            "model": model,
            "instructions": context,
            "input": [["role": "user", "content": content]],
            "max_output_tokens": 1800
        ]
        if let previousResponseID { body["previous_response_id"] = previousResponseID }
        if webSearchEnabled { body["tools"] = [["type": "web_search"]] }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.masariData(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIError.invalidResponse }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard (200...299).contains(http.statusCode) else {
            let message = ((json?["error"] as? [String: Any])?["message"] as? String) ?? "OpenAI API error (\(http.statusCode))"
            throw AIError.server(message)
        }
        let id = json?["id"] as? String
        let output = json?["output"] as? [[String: Any]] ?? []
        let contentItems = output.compactMap { $0["content"] as? [[String: Any]] }.flatMap { $0 }
        guard let textItem = contentItems.first(where: { ($0["type"] as? String) == "output_text" }),
              let text = textItem["text"] as? String, !text.isEmpty else { throw AIError.invalidResponse }
        let annotations = textItem["annotations"] as? [[String: Any]] ?? []
        let sources = annotations.compactMap { annotation -> String? in
            guard (annotation["type"] as? String) == "url_citation", let url = annotation["url"] as? String else { return nil }
            let title = (annotation["title"] as? String) ?? url
            return "• \(title): \(url)"
        }
        let uniqueSources = Array(Set(sources)).sorted()
        let finalText = uniqueSources.isEmpty ? text : text + "\n\nالمصادر:\n" + uniqueSources.joined(separator: "\n")
        return Result(text: finalText, id: id)
    }

    private static func sendGemini(text: String, imageData: Data?, context: String, history: [ChatMessage], apiKey: String, model: String) async throws -> Result {
        guard let escapedModel = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(escapedModel):generateContent") else { throw AIError.invalidResponse }
        var contents: [[String: Any]] = history.suffix(20).map { message in
            ["role": message.role == .user ? "user" : "model", "parts": [["text": message.text]]]
        }
        if let imageData, !contents.isEmpty {
            var last = contents.removeLast()
            var parts = last["parts"] as? [[String: Any]] ?? [["text": text]]
            parts.append(["inline_data": ["mime_type": "image/jpeg", "data": imageData.base64EncodedString()]])
            last["parts"] = parts
            contents.append(last)
        }
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": context]]],
            "contents": contents,
            "generationConfig": ["maxOutputTokens": 4000, "temperature": 0.75]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"; request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.masariData(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIError.invalidResponse }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard (200...299).contains(http.statusCode) else {
            let message = ((json?["error"] as? [String: Any])?["message"] as? String) ?? "Gemini API error (\(http.statusCode))"
            throw AIError.server(message)
        }
        let candidates = json?["candidates"] as? [[String: Any]] ?? []
        let content = candidates.first?["content"] as? [String: Any]
        let responseParts = content?["parts"] as? [[String: Any]] ?? []
        let output = responseParts.compactMap { $0["text"] as? String }.joined(separator: "\n")
        guard !output.isEmpty else { throw AIError.invalidResponse }
        return Result(text: output, id: nil)
    }
}

enum AIError: LocalizedError {
    case invalidResponse, server(String)
    var errorDescription: String? {
        switch self { case .invalidResponse: "تعذر قراءة استجابة الذكاء الاصطناعي."; case .server(let message): message }
    }
}

private extension URLSession {
    func masariData(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: AIError.invalidResponse)
                }
            }
            task.resume()
        }
    }
}

enum KeychainService {
    static func save(_ value: String, key: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)
        SecItemAdd([kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecValueData: data, kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as CFDictionary, nil)
    }
    static func load(key: String) -> String? {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func delete(key: String) {
        SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrAccount: key] as CFDictionary)
    }
}

final class StartupChime {
    static let shared = StartupChime()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var audioPlayer: AVAudioPlayer?
    private var configured = false

    func play(tone: StartupTone, customURL: URL?) {
        engine.stop(); player.stop(); audioPlayer?.stop()
        if tone == .custom, let customURL {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                audioPlayer = try AVAudioPlayer(contentsOf: customURL)
                audioPlayer?.volume = 0.75; audioPlayer?.play(); return
            } catch {}
        }
        let sampleRate = 44_100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        if !configured {
            engine.attach(player); engine.connect(player, to: engine.mainMixerNode, format: format)
            configured = true
        }
        let notes: [Double]
        let duration: Double
        switch tone {
        case .soft: notes = [392.00, 493.88, 587.33]; duration = 0.34
        case .bright: notes = [659.25, 783.99, 1046.50]; duration = 0.22
        default: notes = [523.25, 659.25, 783.99]; duration = 0.28
        }
        let frames = AVAudioFrameCount(sampleRate * duration * Double(notes.count))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames), let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frames
        for frame in 0..<Int(frames) {
            let noteIndex = min(Int(Double(frame) / (sampleRate * duration)), notes.count - 1)
            let local = Double(frame) - Double(noteIndex) * sampleRate * duration
            let t = local / sampleRate
            let envelope = min(t / 0.035, 1) * max(0, 1 - t / duration)
            channel[frame] = Float(sin(2 * .pi * notes[noteIndex] * t) * envelope * 0.16)
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try engine.start(); player.scheduleBuffer(buffer) { [weak self] in self?.engine.stop() }; player.play()
        } catch { engine.stop() }
    }
}
