import Foundation
import SwiftUI
import UIKit
import UserNotifications

enum CourseStatus: String, Codable, CaseIterable, Identifiable {
    case completed, current, remaining
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .completed: AppTheme.completed
        case .current: AppTheme.current
        case .remaining: AppTheme.remaining
        }
    }
}

enum RequirementType: String, Codable, CaseIterable, Identifiable {
    case required, elective
    var id: String { rawValue }
}

enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case openAI, gemini
    var id: String { rawValue }
}

enum StartupTone: String, Codable, CaseIterable, Identifiable {
    case classic, soft, bright, custom
    var id: String { rawValue }
}

struct StudentProfile: Codable {
    var arabicName: String
    var englishName: String
    var studentID: String
    var nationalID: String
    var college: String
    var major: String
    var degree: String
    var studyType: String
    var planHours: Int
    var completedHours: Int
    var currentHours: Int
    var gpa: Double
    var universityEmail: String
    var personalEmail: String
    var phone: String
    var academicAdvisor: String
    var officialRemainingOverride: Int? = nil
    var expectedRemainingAfterCurrentOverride: Int? = nil

    var officialRemainingHours: Int { officialRemainingOverride ?? max(planHours - completedHours, 0) }
    var expectedRemainingAfterCurrent: Int { expectedRemainingAfterCurrentOverride ?? max(officialRemainingHours - currentHours, 0) }
}

struct StudentAccount: Identifiable, Hashable {
    var id: String { studentID }
    let name: String
    let studentID: String
    let email: String
    let phone: String
    let currentCourseCodes: [String]
}

struct StudyAttachment: Codable, Identifiable, Hashable {
    enum Kind: String, Codable { case image, audio }
    var id = UUID()
    var kind: Kind
    var fileName: String
}

struct CourseNote: Codable, Identifiable {
    var id = UUID()
    var createdAt = Date()
    var text: String
    var attachments: [StudyAttachment] = []
}

struct Course: Codable, Identifiable {
    var id = UUID()
    var code: String
    var nameAR: String
    var nameEN: String
    var credits: Int
    var status: CourseStatus
    var requirement: RequirementType
    var level: Int
    var prerequisite: String? = nil
    var dayAR: String? = nil
    var dayEN: String? = nil
    var startTime: String? = nil
    var endTime: String? = nil
    var room: String? = nil
    var section: String? = nil
    var instructor: String? = nil
    var notes: [CourseNote] = []
}

struct TranscriptTerm: Codable, Identifiable {
    struct Result: Codable, Identifiable {
        var id = UUID()
        var code: String
        var name: String
        var credits: Int
        var grade: String
        var points: Double
    }
    var id = UUID()
    var title: String
    var hours: Int
    var termGPA: Double
    var cumulativeGPA: Double
    var results: [Result]
}

enum PaymentStatus: String, Codable, CaseIterable, Identifiable {
    case paid, due, partial
    var id: String { rawValue }
}

struct PaymentRecord: Codable, Identifiable {
    var id = UUID()
    var term: String
    var amount: Double
    var paidAmount: Double
    var creditHours: Int? = nil
    var dueDate: Date? = nil
    var status: PaymentStatus
    var note: String
}

enum AcademicEventKind: String, Codable, CaseIterable, Identifiable {
    case assignment, exam
    var id: String { rawValue }
}

struct AcademicEvent: Codable, Identifiable {
    var id = UUID()
    var title: String
    var details: String
    var dueDate: Date
    var kind: AcademicEventKind
    var courseCode: String
    var reminderMinutes: Int
}

struct AppSettings: Codable {
    var language: AppLanguage = .arabic
    var theme: AppThemeMode = .system
    var startupSound = true
    var startupTone: StartupTone = .classic
    var customStartupSoundFile: String? = nil
    var aiProvider: AIProvider = .gemini
    var aiModel = "gpt-5.6-luna"
    var geminiModel = "gemini-3.5-flash-lite"
    var lectureReminderMinutes = 15
    var eventReminderMinutes = 60

    init() {}

    private enum CodingKeys: String, CodingKey {
        case language, theme, startupSound, startupTone, customStartupSoundFile
        case aiProvider, aiModel, geminiModel, lectureReminderMinutes, eventReminderMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .arabic
        theme = try container.decodeIfPresent(AppThemeMode.self, forKey: .theme) ?? .system
        startupSound = try container.decodeIfPresent(Bool.self, forKey: .startupSound) ?? true
        startupTone = try container.decodeIfPresent(StartupTone.self, forKey: .startupTone) ?? .classic
        customStartupSoundFile = try container.decodeIfPresent(String.self, forKey: .customStartupSoundFile)
        aiProvider = try container.decodeIfPresent(AIProvider.self, forKey: .aiProvider) ?? .gemini
        aiModel = try container.decodeIfPresent(String.self, forKey: .aiModel) ?? "gpt-5.6-luna"
        geminiModel = try container.decodeIfPresent(String.self, forKey: .geminiModel) ?? "gemini-3.5-flash-lite"
        lectureReminderMinutes = try container.decodeIfPresent(Int.self, forKey: .lectureReminderMinutes) ?? 15
        eventReminderMinutes = try container.decodeIfPresent(Int.self, forKey: .eventReminderMinutes) ?? 60
    }
}

struct StoredState: Codable {
    var profile: StudentProfile
    var courses: [Course]
    var transcript: [TranscriptTerm]
    var payments: [PaymentRecord]
    var settings: AppSettings
    var events: [AcademicEvent] = []

    private enum CodingKeys: String, CodingKey { case profile, courses, transcript, payments, settings, events }

    init(profile: StudentProfile, courses: [Course], transcript: [TranscriptTerm], payments: [PaymentRecord], settings: AppSettings, events: [AcademicEvent] = []) {
        self.profile = profile
        self.courses = courses
        self.transcript = transcript
        self.payments = payments
        self.settings = settings
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decode(StudentProfile.self, forKey: .profile)
        courses = try container.decode([Course].self, forKey: .courses)
        transcript = try container.decode([TranscriptTerm].self, forKey: .transcript)
        payments = try container.decode([PaymentRecord].self, forKey: .payments)
        settings = try container.decode(AppSettings.self, forKey: .settings)
        events = try container.decodeIfPresent([AcademicEvent].self, forKey: .events) ?? []
    }
}

enum LoginResult {
    case success
    case unknownStudent
    case invalidPassword
}

final class AppStore: ObservableObject {
    @Published var profile: StudentProfile
    @Published var courses: [Course]
    @Published var transcript: [TranscriptTerm]
    @Published var payments: [PaymentRecord]
    @Published var settings: AppSettings
    @Published var events: [AcademicEvent]
    @Published var isAuthenticated = false
    @Published var currentAccount: StudentAccount?

    let hourCost: Double = 1_150
    private var stateURL: URL
    private let documentsURL: URL
    private let rememberedStudentKey = "aec-remembered-student"

    init() {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentsURL = folder
        stateURL = folder.appendingPathComponent("aec-state-guest.json")
        let seed = Self.seedState()
        profile = seed.profile
        courses = seed.courses
        transcript = seed.transcript
        payments = seed.payments
        settings = seed.settings
        events = seed.events
        if let rememberedID = UserDefaults.standard.string(forKey: rememberedStudentKey),
           let account = StudentDirectory.account(studentID: rememberedID) {
            activate(account: account, remember: true)
        }
    }

    func t(_ ar: String, _ en: String) -> String { settings.language == .arabic ? ar : en }
    func courseName(_ course: Course) -> String { settings.language == .arabic ? course.nameAR : course.nameEN }

    func save() {
        objectWillChange.send()
        let state = StoredState(profile: profile, courses: courses, transcript: transcript, payments: payments, settings: settings, events: events)
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }

    func login(studentID: String, password: String, remember: Bool) -> LoginResult {
        let cleanID = studentID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let account = StudentDirectory.account(studentID: cleanID) else { return .unknownStudent }
        let storedPIN = KeychainService.load(key: "aec-pin-\(cleanID)") ?? "12345678"
        guard password == storedPIN else { return .invalidPassword }
        activate(account: account, remember: remember)
        return .success
    }

    func logout() {
        save()
        UserDefaults.standard.removeObject(forKey: rememberedStudentKey)
        currentAccount = nil
        isAuthenticated = false
    }

    func updatePIN(current: String, newPIN: String) -> Bool {
        guard let id = currentAccount?.studentID else { return false }
        let stored = KeychainService.load(key: "aec-pin-\(id)") ?? "12345678"
        guard current == stored, (1...8).contains(newPIN.count), newPIN.allSatisfy({ $0.isNumber }) else { return false }
        KeychainService.save(newPIN, key: "aec-pin-\(id)")
        return true
    }

    func resetPINToInitial(studentID: String) -> StudentAccount? {
        guard let account = StudentDirectory.account(studentID: studentID.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        KeychainService.delete(key: "aec-pin-\(account.studentID)")
        return account
    }

    private func activate(account: StudentAccount, remember: Bool) {
        currentAccount = account
        stateURL = documentsURL.appendingPathComponent("aec-state-\(account.studentID).json")
        let legacyURL = documentsURL.appendingPathComponent("masari-state.json")
        let sourceURL = FileManager.default.fileExists(atPath: stateURL.path) ? stateURL : (account.studentID == "462211364" ? legacyURL : stateURL)
        if let data = try? Data(contentsOf: sourceURL), let saved = try? JSONDecoder().decode(StoredState.self, from: data) {
            profile = saved.profile; courses = saved.courses; transcript = saved.transcript
            payments = saved.payments; settings = saved.settings; events = saved.events
        } else {
            let initial = Self.state(for: account)
            profile = initial.profile; courses = initial.courses; transcript = initial.transcript
            payments = initial.payments; settings = initial.settings; events = initial.events
        }
        profile.arabicName = account.name
        profile.studentID = account.studentID
        profile.universityEmail = account.email
        if !account.phone.isEmpty { profile.phone = account.phone }
        migrateLegacyData()
        if remember { UserDefaults.standard.set(account.studentID, forKey: rememberedStudentKey) }
        else { UserDefaults.standard.removeObject(forKey: rememberedStudentKey) }
        isAuthenticated = true
        save()
        NotificationManager.shared.refresh(store: self)
    }

    func updateCourse(_ course: Course) {
        guard let index = courses.firstIndex(where: { $0.id == course.id }) else { return }
        courses[index] = course
        save()
    }

    func addCourse(_ course: Course) {
        courses.append(course)
        save()
    }

    func deleteCourse(_ courseID: UUID) {
        if let course = courses.first(where: { $0.id == courseID }) {
            course.notes.flatMap { $0.attachments }.forEach(deleteMediaFile)
        }
        courses.removeAll { $0.id == courseID }
        save()
    }

    func removeCourseFromSchedule(_ courseID: UUID) {
        guard let index = courses.firstIndex(where: { $0.id == courseID }) else { return }
        courses[index].status = .remaining
        courses[index].dayAR = nil; courses[index].dayEN = nil
        courses[index].startTime = nil; courses[index].endTime = nil
        courses[index].room = nil; courses[index].section = nil; courses[index].instructor = nil
        save()
    }

    func addNote(to courseID: UUID, text: String, attachments: [StudyAttachment]) {
        guard let index = courses.firstIndex(where: { $0.id == courseID }) else { return }
        courses[index].notes.insert(CourseNote(text: text, attachments: attachments), at: 0)
        save()
    }

    func deleteNote(courseID: UUID, noteID: UUID) {
        guard let index = courses.firstIndex(where: { $0.id == courseID }) else { return }
        if let note = courses[index].notes.first(where: { $0.id == noteID }) {
            note.attachments.forEach(deleteMediaFile)
        }
        courses[index].notes.removeAll { $0.id == noteID }
        save()
    }

    func updateNote(courseID: UUID, note: CourseNote) {
        guard let courseIndex = courses.firstIndex(where: { $0.id == courseID }),
              let noteIndex = courses[courseIndex].notes.firstIndex(where: { $0.id == note.id }) else { return }
        let oldFiles = Set(courses[courseIndex].notes[noteIndex].attachments.map { $0.fileName })
        let newFiles = Set(note.attachments.map { $0.fileName })
        courses[courseIndex].notes[noteIndex] = note
        oldFiles.subtracting(newFiles).forEach { deleteMediaFile(named: $0) }
        save()
    }

    func mediaDirectory() -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("StudyMedia", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func saveImageData(_ data: Data) -> StudyAttachment? {
        let name = "IMG-\(UUID().uuidString).jpg"
        let url = mediaDirectory().appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return StudyAttachment(kind: .image, fileName: name)
        } catch { return nil }
    }

    func mediaURL(for attachment: StudyAttachment) -> URL { mediaDirectory().appendingPathComponent(attachment.fileName) }

    func deleteMediaFile(_ attachment: StudyAttachment) { deleteMediaFile(named: attachment.fileName) }

    private func deleteMediaFile(named name: String) {
        try? FileManager.default.removeItem(at: mediaDirectory().appendingPathComponent(name))
    }

    func addTranscriptTerm(_ term: TranscriptTerm) { transcript.insert(term, at: 0); save() }
    func updateTranscriptTerm(_ term: TranscriptTerm) {
        guard let index = transcript.firstIndex(where: { $0.id == term.id }) else { return }
        transcript[index] = term; save()
    }
    func deleteTranscriptTerm(_ termID: UUID) { transcript.removeAll { $0.id == termID }; save() }

    func addPayment(_ payment: PaymentRecord) { payments.append(payment); save() }
    func updatePayment(_ payment: PaymentRecord) {
        guard let index = payments.firstIndex(where: { $0.id == payment.id }) else { return }
        payments[index] = payment; save()
    }
    func deletePayment(_ paymentID: UUID) { payments.removeAll { $0.id == paymentID }; save() }

    func addEvent(_ event: AcademicEvent) {
        events.append(event); events.sort { $0.dueDate < $1.dueDate }; save()
        NotificationManager.shared.schedule(event: event)
    }

    func updateEvent(_ event: AcademicEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event; events.sort { $0.dueDate < $1.dueDate }; save()
        NotificationManager.shared.schedule(event: event)
    }

    func deleteEvent(_ eventID: UUID) {
        events.removeAll { $0.id == eventID }; save()
        NotificationManager.shared.cancel(identifier: "event-\(eventID.uuidString)")
    }

    func startupSoundsDirectory() -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("StartupSounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func importStartupSound(from sourceURL: URL) -> Bool {
        let access = sourceURL.startAccessingSecurityScopedResource()
        defer { if access { sourceURL.stopAccessingSecurityScopedResource() } }
        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let name = "custom-startup.\(ext)"
        let destination = startupSoundsDirectory().appendingPathComponent(name)
        do {
            if let old = settings.customStartupSoundFile { try? FileManager.default.removeItem(at: startupSoundsDirectory().appendingPathComponent(old)) }
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            settings.customStartupSoundFile = name; settings.startupTone = .custom; settings.startupSound = true
            save(); return true
        } catch { return false }
    }

    var customStartupSoundURL: URL? {
        guard let name = settings.customStartupSoundFile else { return nil }
        let url = startupSoundsDirectory().appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var paidTotal: Double { payments.reduce(0) { $0 + $1.paidAmount } }
    var remainingTotal: Double { payments.reduce(0) { $0 + max($1.amount - $1.paidAmount, 0) } }
    var latestTermGPA: Double { transcript.first?.termGPA ?? 0 }
    var completedCoursesCount: Int { courses.filter { $0.status == .completed }.count }
    var currentCoursesCount: Int { courses.filter { $0.status == .current }.count }
    var upcomingEvents: [AcademicEvent] { events.filter { $0.dueDate > Date() }.sorted { $0.dueDate < $1.dueDate } }

    func nextLectureDate(for course: Course, after date: Date = Date()) -> Date? {
        let weekdayMap = ["الأحد": 1, "الاثنين": 2, "الثلاثاء": 3, "الأربعاء": 4, "الخميس": 5, "الجمعة": 6, "السبت": 7]
        guard let day = course.dayAR, let weekday = weekdayMap[day], let rawTime = course.startTime, rawTime != "—" else { return nil }
        let pieces = rawTime.replacingOccurrences(of: " ", with: "").split(separator: ":")
        guard pieces.count == 2, var hour = Int(pieces[0]) else { return nil }
        let minuteText = pieces[1].filter { $0.isNumber }
        guard let minute = Int(minuteText) else { return nil }
        let isPM = rawTime.contains("م")
        if isPM && hour < 12 { hour += 12 }
        if !isPM && hour == 12 { hour = 0 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Riyadh") ?? .current
        var components = DateComponents()
        components.weekday = weekday; components.hour = hour; components.minute = minute
        return calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime)
    }

    var upcomingLectures: [(Course, Date)] {
        courses.filter { $0.status == .current }.compactMap { course in
            guard let date = nextLectureDate(for: course) else { return nil }
            return (course, date)
        }.sorted { $0.1 < $1.1 }
    }

    private func migrateLegacyData() {
        var changed = false
        if settings.geminiModel.hasPrefix("gemini-2.") || settings.geminiModel == "gemini-3.1-flash-lite" {
            settings.geminiModel = "gemini-3.5-flash-lite"
            changed = true
        }
        if let index = courses.firstIndex(where: { $0.code == "أمن 302" }),
           courses[index].instructor == nil || courses[index].instructor?.contains("عبدالقادر") == true {
            courses[index].instructor = "عبدالعزيز سعيد محمد أحمد أبو حمامة"
            changed = true
        }
        if currentAccount?.studentID == "462211364", !UserDefaults.standard.bool(forKey: "aec-v2-hours-migrated") {
            profile.completedHours = 81
            profile.currentHours = 18
            profile.planHours = 131
            profile.officialRemainingOverride = 51
            profile.expectedRemainingAfterCurrentOverride = 33
            UserDefaults.standard.set(true, forKey: "aec-v2-hours-migrated")
            changed = true
        }
        if changed { save() }
    }

    private static func state(for account: StudentAccount) -> StoredState {
        if account.studentID == "462211364" { return seedState() }
        var state = seedState()
        state.profile.arabicName = account.name
        state.profile.englishName = ""
        state.profile.studentID = account.studentID
        state.profile.nationalID = ""
        state.profile.completedHours = 0
        state.profile.currentHours = 0
        state.profile.gpa = 0
        state.profile.universityEmail = account.email
        state.profile.personalEmail = ""
        state.profile.phone = account.phone
        state.profile.academicAdvisor = ""
        state.profile.officialRemainingOverride = nil
        state.profile.expectedRemainingAfterCurrentOverride = nil
        state.transcript = []
        state.payments = []
        state.events = []
        state.courses = state.courses.map { original in
            var course = original
            course.status = account.currentCourseCodes.contains(course.code) ? .current : .remaining
            course.dayAR = nil; course.dayEN = nil; course.startTime = nil; course.endTime = nil
            course.room = nil; course.section = nil; course.instructor = nil; course.notes = []
            return course
        }
        state.profile.currentHours = state.courses.filter { $0.status == .current }.reduce(0) { $0 + $1.credits }
        return state
    }

    private static func seedState() -> StoredState {
        let profile = StudentProfile(
            arabicName: "رائد بن دخيل الله بن إبراهيم الزهراني",
            englishName: "RAED DAKHILALLAH IBRAHIM ALZAHRANI",
            studentID: "462211364",
            nationalID: "1077856027",
            college: "كلية الشرق العربي للدراسات التطبيقية",
            major: "تقنية المعلومات - مسار الأمن السيبراني",
            degree: "البكالوريوس",
            studyType: "منتظم",
            planHours: 131,
            completedHours: 81,
            currentHours: 18,
            gpa: 2.75,
            universityEmail: "",
            personalEmail: "raid.690@hotmail.com",
            phone: "0558088821",
            academicAdvisor: "أحمد عارف عبداللطيف محمد",
            officialRemainingOverride: 51,
            expectedRemainingAfterCurrentOverride: 33
        )

        func c(_ code: String, _ ar: String, _ en: String, _ status: CourseStatus, _ level: Int, _ requirement: RequirementType = .required, _ prerequisite: String? = nil, credits: Int = 3) -> Course {
            Course(code: code, nameAR: ar, nameEN: en, credits: credits, status: status, requirement: requirement, level: level, prerequisite: prerequisite)
        }

        var courses: [Course] = [
            c("احص 104", "الاحتمالات والإحصاء", "Probability and Statistics", .completed, 1),
            c("تقن 111", "أساسيات الحاسب وتقنية المعلومات", "Computer and IT Fundamentals", .completed, 1),
            c("ريض 102", "الرياضيات لعلوم الحاسب", "Mathematics for Computer Science", .completed, 1),
            c("سلم 101", "المدخل للثقافة الإسلامية", "Introduction to Islamic Culture", .completed, 1),
            c("عرب 101", "مهارات اللغة العربية", "Arabic Language Skills", .completed, 1),
            c("نجم 101", "اللغة الإنجليزية 1", "English Language I", .completed, 1),
            c("تكا 103", "حساب التفاضل والتكامل 1", "Calculus I", .completed, 2),
            c("ريض 105", "الرياضيات المتقطعة", "Discrete Mathematics", .completed, 2),
            c("سلم 102", "الإسلام وبناء المجتمع", "Islam and Society", .completed, 2),
            c("عال 102", "لغة البرمجة 1", "Programming Language I", .completed, 2),
            c("عال 105", "التفكير المنطقي", "Logical Thinking", .completed, 2),
            c("نجم 102", "اللغة الإنجليزية 2", "English Language II", .completed, 2, .required, "نجم 101"),
            c("تكا 206", "حساب التفاضل والتكامل 2", "Calculus II", .completed, 3),
            c("جبر 207", "الجبر الخطي والمعادلات التفاضلية", "Linear Algebra and Differential Equations", .completed, 3),
            c("سلم 103", "النظام الاقتصادي في الإسلام", "Economic System in Islam", .completed, 3),
            c("سلم 104", "النظام السياسي في الإسلام", "Political System in Islam", .completed, 3),
            c("عال 202", "لغة البرمجة 2", "Programming Language II", .completed, 3, .required, "عال 102"),
            c("عال 203", "مبادئ نظم قواعد البيانات", "Database Systems Principles", .completed, 3),
            c("عال 205", "تحليل وتصميم النظم", "Systems Analysis and Design", .completed, 3),
            c("عال 204", "البرمجة الشيئية", "Object-Oriented Programming", .completed, 4),
            c("عال 206", "هندسة البرمجيات", "Software Engineering", .completed, 4),
            c("عال 207", "نظم إدارة قواعد البيانات", "Database Management Systems", .completed, 4),
            c("عال 208", "أساسيات شبكات الحاسب", "Computer Networks Fundamentals", .completed, 4),
            c("عال 312", "ذكاء اصطناعي", "Artificial Intelligence", .completed, 4),
            c("نجم 210", "اللغة الإنجليزية الموسعة", "Extended English", .completed, 4),
            c("عال 310", "تراكيب البيانات", "Data Structures", .completed, 5),
            c("أمن 303", "القرصنة الأخلاقية", "Ethical Hacking", .completed, 6),
            c("أمن 406", "أمن الشبكات", "Network Security", .completed, 7),
            c("أمن 301", "التشفير التطبيقي", "Applied Cryptography", .current, 5),
            c("أمن 302", "مقدمة في الجريمة الإلكترونية والأمن", "Introduction to Cybercrime and Security", .current, 5),
            c("عال 309", "أنظمة التشغيل", "Operating Systems", .current, 5),
            c("عال 311", "إدارة الشبكات وتصميمها", "Network Management and Design", .current, 5),
            c("عال 314", "التنظيم والبناء المعماري للحاسب", "Computer Organization and Architecture", .current, 5),
            c("عال 418", "مشروع 1", "Project I", .current, 6),
            c("أمن 304", "إدارة ومعايير أمن المعلومات", "Information Security Management and Standards", .remaining, 6),
            c("عال 313", "هندسة وتصميم المواقع", "Web Engineering and Design", .remaining, 6),
            c("عال 315", "القضايا الأخلاقية والقانونية في الحوسبة", "Ethical and Legal Issues in Computing", .remaining, 6),
            c("عال 316", "نمذجة الحاسب والمحاكاة", "Computer Modeling and Simulation", .remaining, 6, .required, "نعم"),
            c("أمن 405", "الطب الشرعي الرقمي", "Digital Forensics", .remaining, 7),
            c("عال 419", "مشروع 2", "Project II", .remaining, 7),
            c("نجم 211", "كتابة التقارير", "Report Writing", .remaining, 7, .required, "نعم"),
            c("عال 317", "التدريب الميداني/التدريب التعاوني", "Field / Cooperative Training", .remaining, 8, credits: 6),
            c("عالخ 401", "تعلم الآلة", "Machine Learning", .remaining, 7, .elective),
            c("عالخ 402", "تفاعل الإنسان والحاسب", "Human-Computer Interaction", .remaining, 7, .elective),
            c("عالخ 403", "تصميم المترجم", "Compiler Design", .remaining, 7, .elective),
            c("عالخ 404", "رسومات الحاسب", "Computer Graphics", .remaining, 7, .elective),
            c("عالخ 405", "برمجة الوسائط المتعددة", "Multimedia Programming", .remaining, 7, .elective),
            c("عالخ 406", "الرسومات المتقدمة والمحاكاة الافتراضية", "Advanced Graphics and Virtual Simulation", .remaining, 7, .elective),
            c("عالخ 407", "المنطق الضبابي وتطبيقاته", "Fuzzy Logic and Applications", .remaining, 7, .elective),
            c("عالخ 408", "المعلوماتية الحيوية", "Bioinformatics", .remaining, 7, .elective),
            c("عالخ 409", "الحوسبة السحابية", "Cloud Computing", .remaining, 7, .elective),
            c("عالخ 410", "تطوير البرمجيات السريع", "Rapid Software Development", .remaining, 7, .elective),
            c("عالخ 411", "البرمجة المرئية", "Visual Programming", .remaining, 7, .elective),
            c("عالخ 412", "تطوير تطبيقات الهاتف المحمول", "Mobile Application Development", .remaining, 7, .elective),
            c("عالخ 413", "معالجة الإشارات", "Signal Processing", .remaining, 7, .elective),
            c("عالخ 414", "الأنظمة المضمنة", "Embedded Systems", .remaining, 7, .elective),
            c("عالخ 415", "معالجة الصورة", "Image Processing", .remaining, 7, .elective),
            c("عالخ 416", "واجهة الروبوتية", "Robotics Interface", .remaining, 7, .elective),
            c("عالخ 417", "نظام المعلومات الجغرافي", "Geographic Information Systems", .remaining, 7, .elective),
            c("عالخ 418", "نظم دعم القرار", "Decision Support Systems", .remaining, 7, .elective),
            c("عالخ 419", "التعرف على الأنماط", "Pattern Recognition", .remaining, 7, .elective),
            c("عالخ 420", "الحوسبة المتنقلة", "Mobile Computing", .remaining, 7, .elective),
            c("عالخ 421", "البيانات الكبيرة والتحليلات", "Big Data and Analytics", .remaining, 7, .elective),
            c("عالخ 422", "تحليل البرامج الضارة", "Malware Analysis", .remaining, 7, .elective),
            c("عالخ 423", "بروتوكولات الأمن", "Security Protocols", .remaining, 7, .elective),
            c("عالخ 424", "إخفاء المعلومات", "Information Hiding", .remaining, 7, .elective)
        ]

        let schedules: [String: (String, String, String, String, String, String)] = [
            "عال 309": ("الأحد", "Sunday", "07:00 م", "10:00 م", "213", "محمد أحمد عبدالحميد الرشيدي"),
            "عال 311": ("الثلاثاء", "Tuesday", "07:00 م", "10:00 م", "208", "مصطفى محمود محمد الجيار"),
            "أمن 301": ("الاثنين", "Monday", "07:00 م", "10:00 م", "406", "د. أبو بكر"),
            "أمن 302": ("الأحد", "Sunday", "04:00 م", "07:00 م", "208", "عبدالعزيز سعيد محمد أحمد أبو حمامة"),
            "عال 314": ("الثلاثاء", "Tuesday", "04:00 م", "07:00 م", "412", "محمد أحمد عبدالحميد الرشيدي"),
            "عال 418": ("بالاتفاق", "By arrangement", "—", "—", "—", "لم يحدد من الكلية")
        ]
        let sections = ["عال 309": "113", "عال 311": "124", "أمن 301": "110", "أمن 302": "121", "عال 314": "155", "عال 418": "189"]
        for index in courses.indices {
            if let s = schedules[courses[index].code] {
                courses[index].dayAR = s.0; courses[index].dayEN = s.1
                courses[index].startTime = s.2; courses[index].endTime = s.3
                courses[index].room = s.4; courses[index].instructor = s.5
                courses[index].section = sections[courses[index].code]
            }
        }

        let transcript = [
            TranscriptTerm(title: "الفصل الصيفي 1448 هـ", hours: 9, termGPA: 2.92, cumulativeGPA: 2.75, results: [
                .init(code: "أمن 303", name: "القرصنة الأخلاقية", credits: 3, grade: "ب", points: 9),
                .init(code: "أمن 406", name: "أمن الشبكات", credits: 3, grade: "ج", points: 6),
                .init(code: "عال 310", name: "تراكيب البيانات", credits: 3, grade: "أ", points: 11.25)
            ]),
            TranscriptTerm(title: "الفصل الثاني 1447/1448 هـ", hours: 18, termGPA: 2.67, cumulativeGPA: 2.67, results: [
                .init(code: "عال 204", name: "البرمجة الشيئية", credits: 3, grade: "ب", points: 9),
                .init(code: "عال 206", name: "هندسة البرمجيات", credits: 3, grade: "ج", points: 6),
                .init(code: "عال 207", name: "نظام إدارة قواعد البيانات", credits: 3, grade: "ب", points: 9),
                .init(code: "عال 208", name: "أساسيات شبكات الحاسب", credits: 3, grade: "ج+", points: 7.5),
                .init(code: "عال 312", name: "ذكاء اصطناعي", credits: 3, grade: "ج", points: 6),
                .init(code: "نجم 210", name: "اللغة الإنجليزية الموسعة", credits: 3, grade: "ب+", points: 10.5)
            ])
        ]

        let payments = [
            PaymentRecord(term: "الفصل 462", amount: 21_200, paidAmount: 21_200, status: .paid, note: "يتضمن 500 ريال رسومًا إضافية بحسب المبلغ الظاهر في البوابة"),
            PaymentRecord(term: "الفصل 463", amount: 10_350, paidAmount: 10_350, creditHours: 9, status: .paid, note: "9 ساعات × 1,150 ريال"),
            PaymentRecord(term: "الفصل 471", amount: 20_700, paidAmount: 0, creditHours: 18, status: .due, note: "18 ساعة × 1,150 ريال — حالة مبدئية قابلة للتعديل")
        ]
        return StoredState(profile: profile, courses: courses, transcript: transcript, payments: payments, settings: AppSettings(), events: [])
    }
}



enum StudentDirectory {
    static let accounts: [StudentAccount] = [
        StudentAccount(name: "أحمد بن عطالله بن عبيد بادي الشيباني", studentID: "431210431", email: "431210431@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302"]),
        StudentAccount(name: "أحمد طارق صالح المترك", studentID: "451210221", email: "451210221@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "أسامه بن محمد بن علي محزري", studentID: "461210421", email: "461210421@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "أيمن بن عبدالله بن عبدالرحمن الجماز", studentID: "452210747", email: "452210747@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "ابراهيم بن حسام بن ابراهيم السراج", studentID: "452210851", email: "452210851@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "ابراهيم بن عبدالله بن سعود الحجي", studentID: "461210074", email: "461210074@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "احمد سليمان محمد الفيفي", studentID: "461210753", email: "461210753@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 314"]),
        StudentAccount(name: "اسامة بن سعد بن سعيد الوسام الدوسري", studentID: "462211005", email: "462211005@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "أمن 302", "عال 311"]),
        StudentAccount(name: "اسامه بن عبدالرحمن بن علي الزيد", studentID: "461210143", email: "461210143@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "اسامه بن يحيى بن احمد النعمي", studentID: "462210914", email: "462210914@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 311"]),
        StudentAccount(name: "الدانه بنت عايش بن سفر السميان البقمي", studentID: "462221447", email: "462221447@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "الوليد خالد مسفر التوم العتيبي", studentID: "462211449", email: "462211449@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314"]),
        StudentAccount(name: "امجاد عبدالهادي شبيب القحطاني", studentID: "462221299", email: "462221299@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "اياد بن يحي بن علي فقيهي", studentID: "462211236", email: "462211236@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309"]),
        StudentAccount(name: "ايمن بن مشعل بن محمد الشعيفاني الحربي", studentID: "461210548", email: "461210548@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 314", "عال 418"]),
        StudentAccount(name: "بدر أحمد محمد العلالي", studentID: "441210197", email: "441210197@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "عال 418"]),
        StudentAccount(name: "بدر ابراهيم حسين ايوب طميحي", studentID: "462211138", email: "462211138@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309"]),
        StudentAccount(name: "بدر بن عبدالرحمن بن صالح اللحدان", studentID: "461210219", email: "461210219@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "بسام عبدالعزيز علي الحمدان", studentID: "462211244", email: "462211244@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "بندر عبدالعزيز محمد الحربي", studentID: "461210849", email: "461210849@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "تركي بن محمد بن عبدالعزيز الخنيفري", studentID: "461210512", email: "461210512@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302"]),
        StudentAccount(name: "تركي بن منصور بن بريك الكثيري", studentID: "461210295", email: "461210295@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314", "عال 418"]),
        StudentAccount(name: "تركي عبدالرحمن عبدالله الطامي", studentID: "462211199", email: "462211199@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "تركي فيصل واسم القحطاني", studentID: "462211172", email: "462211172@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302", "عال 314", "عال 418"]),
        StudentAccount(name: "ثامر بن ابراهيم بن محمد الدعيلج", studentID: "461210075", email: "461210075@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "ثامر بن خضر بن محمد الصومالي", studentID: "462211261", email: "462211261@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "حاتم بن معجب بن عبدالله الرساسمه الشهراني", studentID: "461210272", email: "461210272@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "حسين علي حسين البخيتان", studentID: "431210109", email: "431210109@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "عال 314", "عال 311"]),
        StudentAccount(name: "حمد بن حسن بن حمد النجراني", studentID: "462210946", email: "462210946@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "حمد بن عبدالله بن محمد القريوي", studentID: "462210944", email: "462210944@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "حمد بن فارس بن حمد آل فارس", studentID: "461210661", email: "461210661@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "خالد احمد عبدالعزيز البواردي", studentID: "451210282", email: "451210282@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 311"]),
        StudentAccount(name: "خالد بن عبدالله بن مبارك القثانين الشهراني", studentID: "461210542", email: "461210542@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "خالد بن عوض بن زبن المرشدي العتيبي", studentID: "461210834", email: "461210834@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 311"]),
        StudentAccount(name: "خالد بن فهد بن عبدالعزيز القريشي", studentID: "461210318", email: "461210318@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "خالد بن لبنان بن مناحي ال حزيم الدوسري", studentID: "462211455", email: "462211455@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "خالد بن نادر بن محمد النفيعي العتيبي", studentID: "461210773", email: "461210773@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "خالد ظافر بن ماجد الناقول السبيعي", studentID: "461210759", email: "461210759@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314", "عال 311"]),
        StudentAccount(name: "خالد عبدالرحمن عبدالعزيز السنيدي", studentID: "461210797", email: "461210797@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "خالد عبدالعزيز دريهب العنزي", studentID: "461210317", email: "461210317@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "خليوي بن متعب بن خليوي المقاطي العتيبي", studentID: "462211302", email: "462211302@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "دانه بنت عبدالله بن عبدالرحمن بن عتيق", studentID: "462220977", email: "462220977@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "رائد دخيل الله إبراهيم الزهراني", studentID: "462211364", email: "462211364@students.arabeast.edu.sa", phone: "0558088821", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "راكان بن خالد بن علي الرميحي", studentID: "462211178", email: "462211178@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "راكان بن محمد بن سعد الدعجاني العتيبي", studentID: "461210397", email: "461210397@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301"]),
        StudentAccount(name: "راكان سعود عبدالعزيز ابودجين", studentID: "461210820", email: "461210820@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 311"]),
        StudentAccount(name: "رغد محمد سالم السويلم", studentID: "462221150", email: "462221150@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "رياض صالح ضيف الله الجعيد", studentID: "462211432", email: "462211432@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "أمن 302"]),
        StudentAccount(name: "ريان بن احمد بن عائض السليس العتيبي", studentID: "461210362", email: "461210362@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "ريان عبدالله سعيد الغامدي", studentID: "461210116", email: "461210116@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 418"]),
        StudentAccount(name: "ريانه بنت محمد بن سعد آل سهل", studentID: "462221240", email: "462221240@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "زياد بن محمد بن علي كشر", studentID: "461210464", email: "461210464@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "سامي حسن حسين الزهراني", studentID: "462211478", email: "462211478@students.arabeast.edu.sa", phone: "0540006947", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "سامي ساطي ذعار العتيبي", studentID: "461210828", email: "461210828@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 311"]),
        StudentAccount(name: "سطام مارق حمود المطيري", studentID: "461210050", email: "461210050@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 418"]),
        StudentAccount(name: "سعد بن ايهاب بن سعيد هنا", studentID: "451210462", email: "451210462@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "سعد بن صالح بن سالم الشمري", studentID: "451210497", email: "451210497@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309"]),
        StudentAccount(name: "سعد بن ممدوح بن فريجان المخاريم الدوسري", studentID: "452210975", email: "452210975@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "سعود بن فهد بن سلطان العجمي", studentID: "461210446", email: "461210446@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "سعود بن مسفر بن سعود العتيبي", studentID: "461210440", email: "461210440@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "سلمان بن نايف بن ناصر الدسم القحطاني", studentID: "462211421", email: "462211421@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "سليمان بن عبدالله بن سليمان الجنوبي", studentID: "442210774", email: "442210774@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309"]),
        StudentAccount(name: "صبر بن عبدالرحمن بن علي الميموني المطيري", studentID: "462211154", email: "462211154@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "طلال  محمد  صالح العبدلي المالكي", studentID: "442210724", email: "442210724@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "طلال بن محمد بن عبدالله الدبيخي", studentID: "462211426", email: "462211426@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "عبد الله بن معيذر بن محمد المعيذر", studentID: "461210365", email: "461210365@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالاله بن احمد بن ناصر ابوحيمد", studentID: "461210474", email: "461210474@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالرحمن بن ابراهيم بن عبدالرحمن الريس", studentID: "462211390", email: "462211390@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "عبدالرحمن بن عبدالعزيز بن ناصر ابوحيمد", studentID: "462210971", email: "462210971@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301"]),
        StudentAccount(name: "عبدالرحمن بن ناصر بن عبدالرحمن الضويلع", studentID: "461210588", email: "461210588@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالرحمن عبدالسلام عبدالرحمن بن زايد", studentID: "452210827", email: "452210827@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 311"]),
        StudentAccount(name: "عبدالعزيز بليهيد عبدالهادي العتيبي", studentID: "462211246", email: "462211246@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "عبدالعزيز بن حمد بن محمد الفنتوخ", studentID: "462211318", email: "462211318@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "عال 311", "عال 418"]),
        StudentAccount(name: "عبدالعزيز بن فهد بن علي العمران", studentID: "462211121", email: "462211121@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309"]),
        StudentAccount(name: "عبدالعزيز بن فيصل بن مرزوق الفهادى", studentID: "432210726", email: "432210726@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالعزيز سلطان ناصر الخالدي", studentID: "461210599", email: "461210599@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالعزيز محمد عبدالعزيز البراك", studentID: "461210864", email: "461210864@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314", "عال 418"]),
        StudentAccount(name: "عبدالله بن ابراهيم بن عبدالعزيز العبدالسلام", studentID: "462211204", email: "462211204@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "عبدالله بن ابراهيم عايض السبيعي العنزي", studentID: "462211212", email: "462211212@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "عبدالله بن زكريا بن علي المسبح", studentID: "462211286", email: "462211286@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "عال 311"]),
        StudentAccount(name: "عبدالله بن سالم بن احمد غثوان مجرشي", studentID: "461210608", email: "461210608@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالله بن سعد بن عبدالله العثمان", studentID: "452210814", email: "452210814@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302", "عال 418"]),
        StudentAccount(name: "عبدالله بن سعد بن عبدالله المزروع", studentID: "461210507", email: "461210507@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302"]),
        StudentAccount(name: "عبدالله بن سلطان بن عقيل الرحيمي المطيري", studentID: "462211041", email: "462211041@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "عبدالله بن صالح بن عايد السبيعي العنزي", studentID: "462211190", email: "462211190@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "عال 314"]),
        StudentAccount(name: "عبدالله بن طارق بن عبدالله المزيرعي", studentID: "452211024", email: "452211024@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302", "عال 418"]),
        StudentAccount(name: "عبدالله بن عبدالرحمن بن عبداللطيف الدويش", studentID: "462211269", email: "462211269@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301"]),
        StudentAccount(name: "عبدالله بن محمد بن عبيد الطلوحي العنزي", studentID: "461210606", email: "461210606@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالله بن مرسل بن محمد آل مرسل", studentID: "462211438", email: "462211438@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 418"]),
        StudentAccount(name: "عبدالله بن مومي بن سعود المطيري", studentID: "451210355", email: "451210355@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالله بن ناصر بن عبدالله المسعد", studentID: "461210822", email: "461210822@students.arabeast.edu.sa", phone: "0555224897", currentCourseCodes: ["أمن 302"]),
        StudentAccount(name: "عبدالله عبدالرحمن عبدالله الهزاني", studentID: "461210388", email: "461210388@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالله محمد عبدالله العرمان", studentID: "461210013", email: "461210013@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالمجيد ابراهيم عبدالله الدخيل", studentID: "461210685", email: "461210685@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "عبدالمجيد محمد ناصر  السليمان", studentID: "461210370", email: "461210370@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 311", "عال 418"]),
        StudentAccount(name: "عبدالمحسن بن فريح بن يوسف الطويهر", studentID: "451210099", email: "451210099@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309"]),
        StudentAccount(name: "عبدالملك بن منصور بن عوض الروقي", studentID: "462211195", email: "462211195@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "علي بن درويش بن حسن أحمد", studentID: "461210699", email: "461210699@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "علي عوض تركي الحربي", studentID: "461210506", email: "461210506@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "فارس معيض غرم الله الزهراني", studentID: "462211411", email: "462211411@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "فالح ناصر فهد النبيطي السبيعي", studentID: "461210637", email: "461210637@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "فجر بنت جابر بن جميل الاسلمي الشمري", studentID: "462220970", email: "462220970@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "فهد بن خالد بن رامس ال مسفر الأسمري", studentID: "451210516", email: "451210516@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "أمن 302"]),
        StudentAccount(name: "فهد بن خالد بن صالح الصفيان", studentID: "462211406", email: "462211406@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "فهد بن صالح بن عبد الله الحسن", studentID: "442210729", email: "442210729@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "فهد بن عبدالله بن عبدالستار الشمالي", studentID: "462211282", email: "462211282@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "فهد بن عبدالله بن فهد الخطيب", studentID: "462211167", email: "462211167@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "فهد غزاي تركي الشيباني العتيبي", studentID: "461210774", email: "461210774@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "فيصل بن إبراهيم بن ناصر آل دهام التميمي", studentID: "461210046", email: "461210046@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 418"]),
        StudentAccount(name: "فيصل بن ابراهيم بن عبدالرحمن بن هويمل", studentID: "461210443", email: "461210443@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "فيصل بن سالم بن جبران العبيدي القحطاني", studentID: "462211132", email: "462211132@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "فيصل بن عبدالله بن عائض الحارثي", studentID: "462211188", email: "462211188@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "فيصل بن عمر بن مريخان الشيباني العتيبي", studentID: "461210686", email: "461210686@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "عال 314"]),
        StudentAccount(name: "فيصل بن محمد بن راشد الحركان", studentID: "462211396", email: "462211396@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 311"]),
        StudentAccount(name: "فيصل بن محمد بن عبدالله البيشي", studentID: "441210309", email: "441210309@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "فيصل بن ناصر بن فايز الحليسي الشهراني", studentID: "461210105", email: "461210105@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "فيصل معيض غرم الله الزهراني", studentID: "462211412", email: "462211412@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "ليان بنت ماجد بن غلاب العمري الحربي", studentID: "462221112", email: "462221112@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "ماجد بن عبدالله بن قبلان الشطيطي المطيري", studentID: "452210973", email: "452210973@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301"]),
        StudentAccount(name: "مازن بن عابد بن معيبد الشاطري المطيري", studentID: "462211256", email: "462211256@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 311", "عال 418"]),
        StudentAccount(name: "محمد بن مناحي بن مشعان آل عاطف القحطاني", studentID: "461210848", email: "461210848@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314", "عال 418"]),
        StudentAccount(name: "محمد بن نايف بن محمد العصيمي", studentID: "462211316", email: "462211316@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "محمد عبدالله بخيت الدوسري", studentID: "462211280", email: "462211280@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "أمن 302"]),
        StudentAccount(name: "مشاري بن احمد بن علي السالم", studentID: "461210580", email: "461210580@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314", "عال 311", "عال 418"]),
        StudentAccount(name: "مشاري عبدالعزيز راشد الحاتم", studentID: "462210979", email: "462210979@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "مشعل بن عبدالعزيز بن عساف العساف", studentID: "462211018", email: "462211018@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "مصطفى محمود محمد الجيار", studentID: "403", email: "403@arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 311"]),
        StudentAccount(name: "مصعب بن محسن بن غزاي القصيري الحربي", studentID: "461210147", email: "461210147@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 314", "عال 418"]),
        StudentAccount(name: "مقرن بن محمد بن سليمان الشايع", studentID: "452210813", email: "452210813@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302", "عال 418"]),
        StudentAccount(name: "مقعد بن شرار بن بن ذعار النفيعي العتيبي", studentID: "462211218", email: "462211218@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 311"]),
        StudentAccount(name: "مهنا بن فؤاد بن فازع الشبيشيري المطيري", studentID: "452210952", email: "452210952@students.arabeast.edu.sa", phone: "0530705604", currentCourseCodes: ["أمن 302", "عال 418"]),
        StudentAccount(name: "مهند بن محمد بن عبدالله السلوم", studentID: "462211355", email: "462211355@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 311"]),
        StudentAccount(name: "موسى بن ابراهيم بن موسى الصفيان", studentID: "461210066", email: "461210066@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "موسى بن سامي بن موسى الصفيان", studentID: "461210071", email: "461210071@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "ميمونه بنت فهد بن عبدالله بن المحمد الطواله الشمري", studentID: "462221060", email: "462221060@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "ناصر بن ابراهيم بن عبدالعزيز العيد", studentID: "461210376", email: "461210376@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "ناصر بن سعد أحمد القرني", studentID: "462211275", email: "462211275@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "نايف بن سلطان بن نياف المشرافي المطيري", studentID: "461210375", email: "461210375@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314", "عال 418"]),
        StudentAccount(name: "نواف بن بدر بن هايف بن عميره", studentID: "461210435", email: "461210435@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314", "عال 418"]),
        StudentAccount(name: "نواف بن عبدالرحمن بن عبدالعزيز السعيد", studentID: "461210713", email: "461210713@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "نواف بن علي بن محمد المقبل", studentID: "441210188", email: "441210188@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "نواف طارق مبروك البركي", studentID: "461210069", email: "461210069@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "نواف عبدالعزيز جماح الغامدي", studentID: "461210061", email: "461210061@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314", "عال 418"]),
        StudentAccount(name: "نواف نهار عبدالرحمن السويلم", studentID: "461210287", email: "461210287@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "هاني يحي هادي ال همام", studentID: "451210654", email: "451210654@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "هديل ماجد ابراهيم العويد", studentID: "462220935", email: "462220935@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "هياء صالح عبدالعزيز الرميح", studentID: "462221230", email: "462221230@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 314"]),
        StudentAccount(name: "وليد بن خالد بن سعد حيزان", studentID: "452210957", email: "452210957@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302", "عال 418"]),
        StudentAccount(name: "وليد بن محمد بن سعيد جفشر", studentID: "452210868", email: "452210868@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "ياسر بن سليمان بن محمد الناصر", studentID: "452210829", email: "452210829@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "ياسر بن منصور بن حبيب الشبيشيري المطيري", studentID: "461210720", email: "461210720@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "يزيد بن خالد بن مشعوف المشرافي المطيري", studentID: "462211288", email: "462211288@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 301", "عال 309", "أمن 302", "عال 314", "عال 311"]),
        StudentAccount(name: "يزيد بن ماجد بن فيحان الدلبحي العتيبي", studentID: "461210423", email: "461210423@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["أمن 302", "عال 311", "عال 418"]),
        StudentAccount(name: "يزيد رضاء عبدالله الشمري", studentID: "461210286", email: "461210286@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"]),
        StudentAccount(name: "يزيد سليمان محمد الحقيل", studentID: "461210055", email: "461210055@students.arabeast.edu.sa", phone: "", currentCourseCodes: ["عال 418"])
    ]

    static func account(studentID: String) -> StudentAccount? {
        accounts.first { $0.studentID == studentID }
    }
}

final class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func refresh(store: AppStore) {
        requestPermission()
        scheduleLectures(store: store)
        for event in store.upcomingEvents { schedule(event: event) }
    }

    func scheduleLectures(store: AppStore) {
        let center = UNUserNotificationCenter.current()
        let identifiers = store.courses.map { "lecture-\($0.id.uuidString)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Riyadh") ?? .current
        for course in store.courses where course.status == .current {
            guard let next = store.nextLectureDate(for: course)?.addingTimeInterval(TimeInterval(-store.settings.lectureReminderMinutes * 60)) else { continue }
            let components = calendar.dateComponents([.weekday, .hour, .minute], from: next)
            let content = UNMutableNotificationContent()
            content.title = "محاضرة قادمة"
            content.body = "\(course.nameAR) تبدأ بعد \(store.settings.lectureReminderMinutes) دقيقة"
            content.sound = .default
            let request = UNNotificationRequest(identifier: "lecture-\(course.id.uuidString)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
            center.add(request)
        }
    }

    func schedule(event: AcademicEvent) {
        cancel(identifier: "event-\(event.id.uuidString)")
        let fireDate = event.dueDate.addingTimeInterval(TimeInterval(-event.reminderMinutes * 60))
        guard fireDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = event.kind == .exam ? "اختبار قادم" : "تسليم قادم"
        content.body = event.title
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(fireDate.timeIntervalSinceNow, 1), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "event-\(event.id.uuidString)", content: content, trigger: trigger))
    }

    func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
