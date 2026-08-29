import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

struct StudyHubView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selected = 0

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 12) {
                SectionCard {
                    HStack {
                        ZStack { Circle().fill(AppTheme.primary.opacity(0.12)).frame(width: 52, height: 52); Image(systemName: "books.vertical.fill").font(.title2).foregroundColor(AppTheme.primary) }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.t("مركز دراستي", "Study center")).font(.title3.bold())
                            Text(store.t("موادك وجدولك وملاحظاتك في مكان واحد", "Courses, schedule and notes in one place")).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }.padding(.horizontal)
                Picker("", selection: $selected) {
                    Text(store.t("المواد", "Courses")).tag(0)
                    Text(store.t("الجدول", "Schedule")).tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selected == 0 { currentCourses } else { ScheduleView(embedded: true) }
            }
        }
        .navigationTitle(store.t("دراستي", "My study"))
        .keyboardDismissOnTapAndDrag()
    }

    private var currentCourses: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.courses.filter { $0.status == .current }) { course in
                    NavigationLink(destination: CourseDetailView(courseID: course.id)) {
                        SectionCard {
                            HStack(spacing: 13) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14).fill(AppTheme.current.opacity(0.24)).frame(width: 52, height: 52)
                                    Image(systemName: "book.fill").foregroundColor(AppTheme.deepTeal).font(.title3)
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(store.courseName(course)).font(.headline).foregroundColor(.primary)
                                    Text("\(course.code) • \(course.dayAR ?? "") • \(course.startTime ?? "")")
                                        .font(.caption).foregroundColor(.secondary)
                                    Text(course.instructor ?? store.t("لم يحدد الدكتور", "Instructor not set"))
                                        .font(.caption2).foregroundColor(.secondary).lineLimit(1)
                                    if !course.notes.isEmpty {
                                        Label("\(course.notes.count) \(store.t("ملاحظات", "notes"))", systemImage: "note.text")
                                            .font(.caption2).foregroundColor(AppTheme.teal)
                                    }
                                }
                                Spacer()
                                Image(systemName: store.settings.language == .arabic ? "chevron.left" : "chevron.right").foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }.keyboardDismissOnTapAndDrag()
    }
}

struct ScheduleView: View {
    @EnvironmentObject private var store: AppStore
    var embedded = false
    @State private var editRoute: CourseEditRoute?
    @State private var pendingRemove: Course?

    var sortedCourses: [Course] {
        let order = ["الأحد": 0, "الاثنين": 1, "الثلاثاء": 2, "الأربعاء": 3, "الخميس": 4, "بالاتفاق": 5]
        return store.courses.filter { $0.status == .current }.sorted {
            let d0 = order[$0.dayAR ?? ""] ?? 9, d1 = order[$1.dayAR ?? ""] ?? 9
            if d0 == d1 { return ($0.startTime ?? "") < ($1.startTime ?? "") }
            return d0 < d1
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                SectionCard {
                    HStack {
                        Image(systemName: "calendar").font(.largeTitle).foregroundColor(AppTheme.teal)
                        VStack(alignment: .leading) {
                            Text(store.t("الفصل الأول 1448 هـ", "First term 1448 AH")).font(.headline)
                            Text("\(sortedCourses.reduce(0) { $0 + $1.credits }) \(store.t("ساعة • \(sortedCourses.count) مواد", "credits • \(sortedCourses.count) courses"))").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button { addScheduledCourse() } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                    }
                }
                ForEach(sortedCourses) { course in
                    SectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.courseName(course)).font(.headline)
                                    Text(course.code).font(.caption.bold()).foregroundColor(AppTheme.teal)
                                }
                                Spacer()
                                EditDeleteButtons(edit: { editRoute = CourseEditRoute(course: course, isNew: false) }, delete: { pendingRemove = course })
                                Text(store.settings.language == .arabic ? (course.dayAR ?? "") : (course.dayEN ?? ""))
                                    .font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Capsule().fill(AppTheme.current.opacity(0.24)))
                            }
                            Divider()
                            HStack(spacing: 16) {
                                Label("\(course.startTime ?? "—") – \(course.endTime ?? "—")", systemImage: "clock.fill")
                                Label(store.t("قاعة \(course.room ?? "—")", "Room \(course.room ?? "—")"), systemImage: "location.fill")
                            }.font(.caption).foregroundColor(.secondary)
                            Label(course.instructor ?? "—", systemImage: "person.fill").font(.caption)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(embedded ? "" : store.t("جدولي الحالي", "Current schedule"))
        .sheet(item: $editRoute) { route in NavigationView { CourseEditor(course: route.course, isNew: route.isNew) }.navigationViewStyle(StackNavigationViewStyle()) }
        .alert(item: $pendingRemove) { course in
            Alert(title: Text(store.t("إزالة المادة من الجدول؟", "Remove from schedule?")), message: Text(store.t("ستبقى المادة في الخطة وتتحول إلى متبقية.", "The course stays in the plan as remaining.")), primaryButton: .destructive(Text(store.t("إزالة", "Remove"))) { store.removeCourseFromSchedule(course.id) }, secondaryButton: .cancel(Text(store.t("إلغاء", "Cancel"))))
        }
    }

    private func addScheduledCourse() {
        editRoute = CourseEditRoute(course: Course(code: "", nameAR: "", nameEN: "", credits: 3, status: .current, requirement: .required, level: 1), isNew: true)
    }
}

private enum CourseDetailSheet: Identifiable {
    case camera, photoLibrary, edit(Course), note(CourseNote), preview(StudyAttachment)
    var id: String {
        switch self {
        case .camera: return "camera"
        case .photoLibrary: return "photos"
        case .edit(let course): return "edit-\(course.id)"
        case .note(let note): return "note-\(note.id)"
        case .preview(let attachment): return "preview-\(attachment.id)"
        }
    }
}

struct CourseDetailView: View {
    @EnvironmentObject private var store: AppStore
    let courseID: UUID
    @State private var noteText = ""
    @State private var draftAttachments: [StudyAttachment] = []
    @State private var activeSheet: CourseDetailSheet?
    @StateObject private var recorder = AudioRecorderService()

    private var course: Course? { store.courses.first(where: { $0.id == courseID }) }
    private static let noteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ZStack {
            AppBackground()
            if let course {
                ScrollView {
                    VStack(spacing: 14) {
                        courseHeader(course)
                        noteComposer(course)
                        notesList(course)
                    }.padding()
                }.keyboardDismissOnTapAndDrag()
                .navigationTitle(store.courseName(course))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { UIApplication.shared.dismissKeyboard(); activeSheet = .edit(course) } label: { Image(systemName: "pencil.circle.fill") } } }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .camera:
                CameraPicker { image in
                    if let data = image.jpegData(compressionQuality: 0.84), let attachment = store.saveImageData(data) { draftAttachments.append(attachment) }
                }.ignoresSafeArea()
            case .photoLibrary:
                PhotoLibraryPicker { image in
                    if let data = image.jpegData(compressionQuality: 0.84), let attachment = store.saveImageData(data) { draftAttachments.append(attachment) }
                }
            case .edit(let course):
                NavigationView { CourseEditor(course: course, isNew: false) }.navigationViewStyle(StackNavigationViewStyle())
            case .note(let note):
                NavigationView { CourseNoteEditor(courseID: courseID, note: note) }.navigationViewStyle(StackNavigationViewStyle())
            case .preview(let attachment):
                AttachmentViewer(attachment: attachment)
            }
        }
    }

    private func courseHeader(_ course: Course) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack { StatusPill(status: .current); Spacer(); Text(course.code).font(.caption.bold()).foregroundColor(AppTheme.teal) }
                Text(store.courseName(course)).font(.title3.bold())
                HStack { Label(course.dayAR ?? "—", systemImage: "calendar"); Spacer(); Label(course.startTime ?? "—", systemImage: "clock") }
                HStack { Label(store.t("قاعة \(course.room ?? "—")", "Room \(course.room ?? "—")"), systemImage: "location.fill"); Spacer(); Label(store.t("شعبة \(course.section ?? "—")", "Section \(course.section ?? "—")"), systemImage: "number") }
                Label(course.instructor ?? "—", systemImage: "person.fill")
            }.font(.caption).foregroundColor(.secondary)
        }
    }

    private func noteComposer(_ course: Course) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 13) {
                Text(store.t("ملاحظة محاضرة جديدة", "New lecture note")).font(.headline)
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 13).fill(Color(.tertiarySystemBackground))
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color.clear)
                    if noteText.isEmpty {
                        Text(store.t("اكتب شرح الدكتور، المهام، أو أهم النقاط…", "Write the explanation, tasks, or key points…"))
                            .foregroundColor(.secondary).padding(14).allowsHitTesting(false)
                    }
                }
                HStack(spacing: 8) {
                    Button { openCamera() } label: { actionLabel(store.t("تصوير", "Camera"), "camera.fill") }
                    Button { openPhotoLibrary() } label: { actionLabel(store.t("صورة", "Photo"), "photo.fill") }
                    Button { toggleRecording() } label: { actionLabel(recorder.isRecording ? store.t("إيقاف", "Stop") : store.t("تسجيل", "Record"), recorder.isRecording ? "stop.circle.fill" : "mic.fill") }
                        .accentColor(recorder.isRecording ? .red : AppTheme.teal)
                }
                if !draftAttachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(draftAttachments) { attachment in
                                ZStack(alignment: .topTrailing) {
                                    attachmentPreview(attachment)
                                    Button { store.deleteMediaFile(attachment); draftAttachments.removeAll { $0.id == attachment.id } } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.white).background(Circle().fill(Color.red)) }.offset(x: 6, y: -6)
                                }
                            }
                        }
                    }
                }
                Button {
                    UIApplication.shared.dismissKeyboard()
                    store.addNote(to: course.id, text: noteText.trimmingCharacters(in: .whitespacesAndNewlines), attachments: draftAttachments)
                    noteText = ""; draftAttachments = []
                } label: {
                    Label(store.t("حفظ الملاحظة", "Save note"), systemImage: "square.and.arrow.down.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draftAttachments.isEmpty)
            }
        }
    }

    private func notesList(_ course: Course) -> some View {
        VStack(spacing: 12) {
            if course.notes.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "note.text").font(.largeTitle).foregroundColor(.secondary)
                    Text(store.t("لا توجد ملاحظات بعد", "No notes yet")).font(.headline)
                    Text(store.t("أضف أول شرح أو صورة أو تسجيل للمادة", "Add your first note, photo, or recording"))
                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.top, 25)
            } else {
                ForEach(course.notes) { note in
                    SectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(Self.noteDateFormatter.string(from: note.createdAt)).font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Button { UIApplication.shared.dismissKeyboard(); activeSheet = .note(note) } label: { Image(systemName: "pencil").foregroundColor(AppTheme.teal) }
                                Button { store.deleteNote(courseID: course.id, noteID: note.id) } label: { Image(systemName: "trash").foregroundColor(.red) }
                            }
                            if !note.text.isEmpty { Text(note.text) }
                            ForEach(note.attachments) { attachment in attachmentPreview(attachment) }
                        }
                    }
                }
            }
        }
    }

    private func actionLabel(_ title: String, _ icon: String) -> some View {
        Label(title, systemImage: icon).font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 9)
            .frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 11).fill(Color(.tertiarySystemBackground)))
    }

    @ViewBuilder private func attachmentPreview(_ attachment: StudyAttachment) -> some View {
        if attachment.kind == .image, let image = UIImage(contentsOfFile: store.mediaURL(for: attachment).path) {
            Button { UIApplication.shared.dismissKeyboard(); activeSheet = .preview(attachment) } label: { Image(uiImage: image).resizable().scaledToFill().frame(width: 110, height: 84).clipShape(RoundedRectangle(cornerRadius: 11)) }.buttonStyle(PlainButtonStyle())
        } else {
            AudioAttachmentPlayer(url: store.mediaURL(for: attachment))
        }
    }

    private func openCamera() { UIApplication.shared.dismissKeyboard(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { activeSheet = .camera } }
    private func openPhotoLibrary() { UIApplication.shared.dismissKeyboard(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { activeSheet = .photoLibrary } }

    private func toggleRecording() {
        if recorder.isRecording {
            if let url = recorder.stop() {
                draftAttachments.append(StudyAttachment(kind: .audio, fileName: url.lastPathComponent))
            }
        } else {
            recorder.start(in: store.mediaDirectory())
        }
    }
}

struct CourseNoteEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    let courseID: UUID
    @State var note: CourseNote
    @State private var previewAttachment: StudyAttachment?
    @State private var showDeleteAlert = false
    var body: some View {
        Form {
            Section(header: Text(store.t("نص الملاحظة", "Note text"))) { TextEditor(text: $note.text).frame(minHeight: 180) }
            Section(header: Text(store.t("المرفقات", "Attachments"))) {
                if note.attachments.isEmpty { Text(store.t("لا توجد مرفقات", "No attachments")).foregroundColor(.secondary) }
                ForEach(note.attachments) { attachment in
                    HStack {
                        if attachment.kind == .image, let image = UIImage(contentsOfFile: store.mediaURL(for: attachment).path) {
                            Button { previewAttachment = attachment } label: { Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 58).clipShape(RoundedRectangle(cornerRadius: 9)) }.buttonStyle(PlainButtonStyle())
                        } else { AudioAttachmentPlayer(url: store.mediaURL(for: attachment)) }
                        Spacer(); Button { note.attachments.removeAll { $0.id == attachment.id } } label: { Image(systemName: "trash.circle.fill").foregroundColor(.red).font(.title3) }
                    }
                }
            }
            Section { Button { showDeleteAlert = true } label: { Label(store.t("حذف الملاحظة كاملة", "Delete entire note"), systemImage: "trash.fill").foregroundColor(.red) } }
        }
        .navigationTitle(store.t("تعديل الملاحظة", "Edit note"))
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(store.t("إلغاء", "Cancel")) { presentationMode.wrappedValue.dismiss() } }; ToolbarItem(placement: .navigationBarTrailing) { Button(store.t("حفظ", "Save")) { UIApplication.shared.dismissKeyboard(); store.updateNote(courseID: courseID, note: note); presentationMode.wrappedValue.dismiss() } } }
        .sheet(item: $previewAttachment) { attachment in AttachmentViewer(attachment: attachment) }
        .alert(isPresented: $showDeleteAlert) { Alert(title: Text(store.t("حذف الملاحظة؟", "Delete note?")), primaryButton: .destructive(Text(store.t("حذف", "Delete"))) { store.deleteNote(courseID: courseID, noteID: note.id); presentationMode.wrappedValue.dismiss() }, secondaryButton: .cancel(Text(store.t("إلغاء", "Cancel")))) }
        .keyboardDismissOnTapAndDrag()
    }
}

struct AttachmentViewer: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    let attachment: StudyAttachment
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                if attachment.kind == .image, let image = UIImage(contentsOfFile: store.mediaURL(for: attachment).path) { ZoomableImageView(image: image).ignoresSafeArea(edges: .bottom) }
                else { AudioAttachmentPlayer(url: store.mediaURL(for: attachment)) }
            }
            .navigationTitle(store.t("استعراض المرفق", "Attachment preview"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(store.t("تم", "Done")) { presentationMode.wrappedValue.dismiss() } } }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tag = 71
        scrollView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.frameLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.frameLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        (uiView.viewWithTag(71) as? UIImageView)?.image = image
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { scrollView.viewWithTag(71) }
    }
}

struct AudioAttachmentPlayer: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var playback = AudioPlaybackService()
    let url: URL

    var body: some View {
        Button { playback.toggle(url: url) } label: {
            Label(playback.isPlaying ? store.t("إيقاف التسجيل", "Stop recording") : store.t("تشغيل التسجيل", "Play recording"), systemImage: playback.isPlaying ? "stop.fill" : "play.fill")
                .font(.caption.bold()).foregroundColor(AppTheme.teal).padding(10)
                .background(RoundedRectangle(cornerRadius: 11).fill(AppTheme.teal.opacity(0.10)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private final class AudioPlaybackService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?

    func toggle(url: URL) {
        if isPlaying {
            player?.stop(); isPlaying = false
        } else {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.delegate = self
                player?.play()
                isPlaying = true
            } catch { isPlaying = false }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { isPlaying = false }
}

final class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    private var recorder: AVAudioRecorder?

    func start(in folder: URL) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                    let url = folder.appendingPathComponent("REC-\(UUID().uuidString).m4a")
                    self?.recorder = try AVAudioRecorder(url: url, settings: [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44_100,
                        AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ])
                    self?.recorder?.record()
                    self?.isRecording = true
                } catch { self?.isRecording = false }
            }
        }
    }

    func stop() -> URL? {
        let url = recorder?.url
        recorder?.stop(); recorder = nil; isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
        return url
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                picker.dismiss(animated: true)
                return
            }
            picker.dismiss(animated: true)
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage { self.parent.onImage(image) }
                }
            }
        }
    }
}
