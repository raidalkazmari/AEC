import SwiftUI
import Foundation

struct CourseEditRoute: Identifiable { let id = UUID(); let course: Course; let isNew: Bool }
struct TranscriptEditRoute: Identifiable { let id = UUID(); let term: TranscriptTerm; let isNew: Bool }

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 17) {
                    appHeader
                    greeting
                    academicProgress
                    hourCards
                    gpaCards
                    courseAndFinanceCards
                    upcomingLectures
                    quickAccess
                    deadlines
                    currentCourses
                }.padding(.horizontal, 16).padding(.bottom, 26)
            }.keyboardDismissOnTapAndDrag()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }

    private var appHeader: some View {
        ZStack {
            RaedLogoView(size: 48)
            HStack(spacing: 11) {
                NavigationLink(destination: ProfileView()) {
                    ZStack {
                        Circle().fill(AppTheme.primary.opacity(0.12)).frame(width: 44, height: 44)
                        Image(systemName: "person.crop.circle.fill").font(.title2).foregroundColor(AppTheme.primary)
                    }
                }
                Spacer()
                NavigationLink(destination: SearchView()) { HeaderIcon(icon: "magnifyingglass") }
                NavigationLink(destination: SupportView()) { HeaderIcon(icon: "headphones") }
                NavigationLink(destination: NotificationCenterView()) {
                    ZStack(alignment: .topTrailing) {
                        HeaderIcon(icon: "bell.fill")
                        if !store.upcomingEvents.isEmpty {
                            Circle().fill(.red).frame(width: 9, height: 9).overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                        }
                    }
                }
            }
        }
        .padding(.top, 10)
        .buttonStyle(PlainButtonStyle())
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(store.t("أهلًا \(store.profile.arabicName.split(separator: " ").first.map(String.init) ?? "طالب") 👋", "Welcome 👋"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(store.profile.major).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var academicProgress: some View {
        SectionCard {
            HStack(spacing: 20) {
                ProgressRing(
                    progress: Double(store.profile.completedHours) / Double(store.profile.planHours),
                    value: "\(Int((Double(store.profile.completedHours) / Double(store.profile.planHours)) * 100))%",
                    caption: store.t("من الخطة", "of plan")
                )
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.t("تقدمك الأكاديمي", "Academic progress")).font(.title3.bold())
                    Label("\(store.profile.completedHours) \(store.t("ساعة مجتازة", "completed credits"))", systemImage: "checkmark.seal.fill").foregroundColor(AppTheme.completed)
                    Label("\(store.profile.currentHours) \(store.t("ساعة حالية", "current credits"))", systemImage: "book.fill").foregroundColor(AppTheme.gold)
                    Text(store.t("بعد اجتياز الفصل: يتبقى \(store.profile.expectedRemainingAfterCurrent) ساعة", "After this term: \(store.profile.expectedRemainingAfterCurrent) credits remain"))
                        .font(.caption.weight(.bold)).foregroundColor(AppTheme.primary)
                }
                .font(.caption)
            }
        }
    }

    private var hourCards: some View {
        HStack(spacing: 10) {
            MiniMetric(title: "المجتازة", value: "\(store.profile.completedHours)", icon: "checkmark.seal.fill", color: AppTheme.completed)
            MiniMetric(title: "الحالية", value: "\(store.profile.currentHours)", icon: "book.closed.fill", color: AppTheme.gold)
            MiniMetric(title: "المتبقية", value: "\(store.profile.officialRemainingHours)", icon: "hourglass", color: AppTheme.violet)
        }
    }

    private var gpaCards: some View {
        HStack(spacing: 11) {
            WideMetric(title: "المعدل الفصلي الأخير", value: String(format: "%.2f", store.latestTermGPA), icon: "chart.line.uptrend.xyaxis", color: AppTheme.cyan)
            WideMetric(title: "المعدل التراكمي", value: String(format: "%.2f", store.profile.gpa), icon: "chart.bar.fill", color: AppTheme.primary)
        }
    }

    private var courseAndFinanceCards: some View {
        VStack(spacing: 11) {
            HStack(spacing: 11) {
                WideMetric(title: "المواد المجتازة", value: "\(store.completedCoursesCount)", icon: "checkmark.circle.fill", color: AppTheme.success)
                WideMetric(title: "المواد الحالية", value: "\(store.currentCoursesCount)", icon: "books.vertical.fill", color: AppTheme.violet)
            }
            HStack(spacing: 11) {
                WideMetric(title: "المبلغ المدفوع", value: store.paidTotal.sar, icon: "checkmark.shield.fill", color: AppTheme.success)
                WideMetric(title: "المبلغ المتبقي", value: store.remainingTotal.sar, icon: "creditcard.fill", color: .orange)
            }
        }
    }

    private var upcomingLectures: some View {
        DashboardSection(title: "المحاضرات القادمة", icon: "clock.badge.fill") {
            if store.upcomingLectures.isEmpty {
                EmptyCompact(text: "لا توجد محاضرات محددة في الجدول")
            } else {
                ForEach(Array(store.upcomingLectures.prefix(3)).map { LecturePreview(course: $0.0, date: $0.1) }) { item in
                    HStack(spacing: 12) {
                        DateBadge(date: item.date)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(store.courseName(item.course)).font(.subheadline.bold())
                            Text("\(item.course.startTime ?? "—") • \(item.course.room.map { "قاعة \($0)" } ?? "")")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var quickAccess: some View {
        DashboardSection(title: "وصول سريع", icon: "bolt.fill") {
            HStack(spacing: 10) {
                NavigationLink(destination: ScheduleView()) { QuickButton(title: "الجدول", icon: "calendar", color: AppTheme.primary) }
                NavigationLink(destination: TranscriptView()) { QuickButton(title: "السجل", icon: "doc.text.fill", color: AppTheme.gold) }
                NavigationLink(destination: AIView()) { QuickButton(title: "اسأل الذكاء", icon: "sparkles", color: AppTheme.violet) }
            }.buttonStyle(PlainButtonStyle())
        }
    }

    private var deadlines: some View {
        DashboardSection(title: "التسليمات والاختبارات القادمة", icon: "calendar.badge.exclamationmark") {
            if store.upcomingEvents.isEmpty {
                VStack(spacing: 10) {
                    EmptyCompact(text: "لا توجد مواعيد مضافة")
                    NavigationLink(destination: NotificationCenterView()) { Label("إضافة موعد", systemImage: "plus.circle.fill").font(.caption.bold()) }
                }
            } else {
                ForEach(Array(store.upcomingEvents.prefix(3))) { event in EventCompactRow(event: event) }
            }
        }
    }

    private var currentCourses: some View {
        DashboardSection(title: store.t("مواد الفصل الحالي", "Current courses"), icon: "books.vertical.fill") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(store.courses.filter { $0.status == .current }) { course in
                    NavigationLink(destination: CourseDetailView(courseID: course.id)) { CourseRow(course: course) }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

private struct LecturePreview: Identifiable {
    var id: UUID { course.id }
    let course: Course
    let date: Date
}

private struct HeaderIcon: View {
    let icon: String
    var body: some View {
        Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundColor(AppTheme.primary)
            .frame(width: 38, height: 38).background(Circle().fill(Color(.secondarySystemBackground)))
            .overlay(Circle().stroke(AppTheme.primary.opacity(0.10)))
    }
}

private struct MiniMetric: View {
    let title: String, value: String, icon: String
    let color: Color
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon).foregroundColor(color)
            Text(value).font(.system(.title3, design: .rounded).bold())
            Text(title).font(.caption2).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 19).fill(color.opacity(0.10)))
    }
}

private struct WideMetric: View {
    let title, value, icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundColor(color).font(.title3.bold())
            Text(value).font(.system(.title3, design: .rounded).bold()).lineLimit(1).minimumScaleFactor(0.65)
            Text(title).font(.caption).foregroundColor(.secondary).lineLimit(1).minimumScaleFactor(0.8)
        }.frame(maxWidth: .infinity, minHeight: 105, alignment: .leading).padding(15)
            .background(RoundedRectangle(cornerRadius: 21).fill(LinearGradient(colors: [color.opacity(0.14), color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)))
    }
}

private struct DashboardSection<Content: View>: View {
    let title, icon: String
    let content: Content
    init(title: String, icon: String, @ViewBuilder content: () -> Content) { self.title = title; self.icon = icon; self.content = content() }
    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 13) {
                Label(title, systemImage: icon).font(.headline).foregroundColor(.primary)
                content
            }
        }
    }
}

private struct EmptyCompact: View {
    let text: String
    var body: some View { Text(text).font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8) }
}

private struct DateBadge: View {
    let date: Date
    var body: some View {
        VStack(spacing: 2) {
            Text(date, style: .time).font(.caption.bold())
            Text(date, style: .date).font(.system(size: 8)).lineLimit(1)
        }.frame(width: 72, height: 48).background(RoundedRectangle(cornerRadius: 13).fill(AppTheme.primary.opacity(0.10))).foregroundColor(AppTheme.primary)
    }
}

private struct EventCompactRow: View {
    let event: AcademicEvent
    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: event.kind == .exam ? "doc.text.fill" : "tray.and.arrow.down.fill")
                .foregroundColor(event.kind == .exam ? .red : AppTheme.violet).frame(width: 34, height: 34)
                .background(Circle().fill((event.kind == .exam ? Color.red : AppTheme.violet).opacity(0.10)))
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(.subheadline.bold())
                Text(event.dueDate, style: .relative).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if !event.courseCode.isEmpty { Text(event.courseCode).font(.caption2.bold()).foregroundColor(AppTheme.primary) }
        }
    }
}

private struct QuickButton: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3.bold()).foregroundColor(color)
            Text(title).font(.caption.bold()).foregroundColor(.primary).lineLimit(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 13)
        .background(RoundedRectangle(cornerRadius: 15).fill(color.opacity(0.10)))
    }
}

struct PlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedStatus: CourseStatus?
    @State private var showElectives = false
    @State private var editRoute: CourseEditRoute?
    @State private var pendingDelete: Course?

    var filtered: [Course] {
        store.courses.filter { course in
            (selectedStatus == nil || course.status == selectedStatus) && (showElectives || course.requirement == .required)
        }
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                LazyVStack(spacing: 14) {
                    planProgress
                    legend
                    Toggle(store.t("إظهار مواد عالخ الاختيارية", "Show AALKH electives"), isOn: $showElectives).accentColor(AppTheme.teal)
                    ForEach(Dictionary(grouping: filtered, by: \.level).keys.sorted(), id: \.self) { level in
                        SectionCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.t("المستوى \(level)", "Level \(level)")).font(.headline).foregroundColor(AppTheme.deepTeal)
                                ForEach(filtered.filter { $0.level == level }) { course in
                                    HStack(spacing: 8) {
                                        CourseRow(course: course)
                                        EditDeleteButtons(edit: { editRoute = CourseEditRoute(course: course, isNew: false) }, delete: { pendingDelete = course })
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }.keyboardDismissOnTapAndDrag()
        }
        .navigationTitle(store.t("الخطة الدراسية", "Study plan"))
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { editRoute = CourseEditRoute(course: Course(code: "", nameAR: "", nameEN: "", credits: 3, status: .remaining, requirement: .required, level: 1), isNew: true) } label: { Image(systemName: "plus.circle.fill") } } }
        .sheet(item: $editRoute) { route in NavigationView { CourseEditor(course: route.course, isNew: route.isNew) }.navigationViewStyle(StackNavigationViewStyle()) }
        .alert(item: $pendingDelete) { course in
            Alert(title: Text(store.t("حذف المادة؟", "Delete course?")), message: Text(store.courseName(course)), primaryButton: .destructive(Text(store.t("حذف", "Delete"))) { store.deleteCourse(course.id) }, secondaryButton: .cancel(Text(store.t("إلغاء", "Cancel"))))
        }
    }

    private var planProgress: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack { Label("ملخص الخطة", systemImage: "chart.pie.fill").font(.headline); Spacer(); Text("\(store.profile.planHours) ساعة").font(.caption.bold()).foregroundColor(AppTheme.primary) }
                HStack(spacing: 9) {
                    MiniMetric(title: "مجتاز", value: "\(store.profile.completedHours)", icon: "checkmark.seal.fill", color: AppTheme.completed)
                    MiniMetric(title: "حالي", value: "\(store.profile.currentHours)", icon: "book.fill", color: AppTheme.gold)
                    MiniMetric(title: "بعد الفصل", value: "\(store.profile.expectedRemainingAfterCurrent)", icon: "hourglass", color: AppTheme.violet)
                }
                Text("يُحسب الملخص من بيانات الطالب، وليس من عدد المواد الظاهرة فقط؛ ويشمل الساعات المعادلة من الدبلوم.")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var legend: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(store.t("حالة المواد", "Course status")).font(.headline)
                HStack(spacing: 8) {
                    filterButton(nil, store.t("الكل", "All"), AppTheme.teal)
                    filterButton(.completed, store.t("مجتاز", "Done"), AppTheme.completed)
                    filterButton(.current, store.t("حالي", "Current"), AppTheme.current)
                    filterButton(.remaining, store.t("متبقٍ", "Left"), AppTheme.remaining)
                }
                Text(store.t("أمن، عال، ونجم: متطلبات • عالخ: مواد اختيارية (تحتاج 6 ساعات)", "AMN, AAL and NAJM: required • AALKH: electives (6 credits needed)"))
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private func filterButton(_ status: CourseStatus?, _ title: String, _ color: Color) -> some View {
        Button {
            withAnimation { selectedStatus = status }
        } label: {
            Text(title).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(selectedStatus == status ? color.opacity(0.25) : Color(.tertiarySystemBackground)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CourseEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var course: Course
    var isNew = false
    var body: some View {
        Form {
            Section(header: Text(store.t("بيانات المادة", "Course information"))) {
                TextField(store.t("رمز المادة", "Course code"), text: $course.code)
                TextField(store.t("اسم المادة بالعربية", "Arabic name"), text: $course.nameAR)
                TextField(store.t("اسم المادة بالإنجليزية", "English name"), text: $course.nameEN)
                TextField(store.t("عدد الساعات", "Credits"), value: $course.credits, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
                TextField(store.t("المستوى", "Level"), value: $course.level, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
                Picker(store.t("الحالة", "Status"), selection: $course.status) {
                    Text(store.t("مجتاز", "Completed")).tag(CourseStatus.completed); Text(store.t("حالي", "Current")).tag(CourseStatus.current); Text(store.t("متبقٍ", "Remaining")).tag(CourseStatus.remaining)
                }
                Picker(store.t("نوع المادة", "Requirement"), selection: $course.requirement) {
                    Text(store.t("متطلب", "Required")).tag(RequirementType.required); Text(store.t("اختيارية", "Elective")).tag(RequirementType.elective)
                }
                TextField(store.t("المتطلب السابق", "Prerequisite"), text: Binding(orEmpty: $course.prerequisite))
            }
            Section(header: Text(store.t("بيانات الجدول", "Schedule information"))) {
                TextField(store.t("اليوم بالعربية", "Arabic day"), text: Binding(orEmpty: $course.dayAR))
                TextField(store.t("اليوم بالإنجليزية", "English day"), text: Binding(orEmpty: $course.dayEN))
                TextField(store.t("وقت البداية", "Start time"), text: Binding(orEmpty: $course.startTime))
                TextField(store.t("وقت النهاية", "End time"), text: Binding(orEmpty: $course.endTime))
                TextField(store.t("القاعة", "Room"), text: Binding(orEmpty: $course.room))
                TextField(store.t("الشعبة", "Section"), text: Binding(orEmpty: $course.section))
                TextField(store.t("اسم الدكتور", "Instructor"), text: Binding(orEmpty: $course.instructor))
            }
        }
        .navigationTitle(isNew ? store.t("إضافة مادة", "Add course") : store.t("تعديل المادة", "Edit course"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button(store.t("إلغاء", "Cancel")) { presentationMode.wrappedValue.dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) { Button(store.t("حفظ", "Save")) { course.credits = max(course.credits, 0); course.level = max(course.level, 1); if isNew { store.addCourse(course) } else { store.updateCourse(course) }; presentationMode.wrappedValue.dismiss() }.disabled(course.code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || course.nameAR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }
        .keyboardDismissOnTapAndDrag()
    }
}

struct TranscriptView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editRoute: TranscriptEditRoute?
    @State private var pendingDelete: TranscriptTerm?
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        StatCard(title: store.t("الساعات المجتازة", "Completed credits"), value: "\(store.profile.completedHours)", icon: "checkmark.seal", color: AppTheme.completed)
                        StatCard(title: store.t("المعدل", "GPA"), value: String(format: "%.2f", store.profile.gpa), icon: "chart.bar.fill", color: AppTheme.gold)
                    }
                    ForEach(store.transcript) { term in
                        SectionCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack { Text(term.title).font(.headline); Spacer(); EditDeleteButtons(edit: { editRoute = TranscriptEditRoute(term: term, isNew: false) }, delete: { pendingDelete = term }) }
                                ForEach(term.results) { result in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(result.name).font(.subheadline.weight(.semibold))
                                            Text(result.code).font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(result.grade).font(.headline).frame(width: 36, height: 36).background(Circle().fill(AppTheme.teal.opacity(0.12)))
                                    }
                                    Divider()
                                }
                                HStack {
                                    Text(store.t("الفصلي \(String(format: "%.2f", term.termGPA))", "Term \(String(format: "%.2f", term.termGPA))"))
                                    Spacer()
                                    Text(store.t("التراكمي \(String(format: "%.2f", term.cumulativeGPA))", "Cumulative \(String(format: "%.2f", term.cumulativeGPA))"))
                                }.font(.caption.bold()).foregroundColor(AppTheme.deepTeal)
                            }
                        }
                    }
                }.padding()
            }
        }
        .navigationTitle(store.t("السجل الأكاديمي", "Transcript"))
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { editRoute = TranscriptEditRoute(term: TranscriptTerm(title: "", hours: 0, termGPA: 0, cumulativeGPA: store.profile.gpa, results: []), isNew: true) } label: { Image(systemName: "plus.circle.fill") } } }
        .sheet(item: $editRoute) { route in NavigationView { TranscriptTermEditor(term: route.term, isNew: route.isNew) }.navigationViewStyle(StackNavigationViewStyle()) }
        .alert(item: $pendingDelete) { term in
            Alert(title: Text(store.t("حذف الفصل؟", "Delete term?")), message: Text(term.title), primaryButton: .destructive(Text(store.t("حذف", "Delete"))) { store.deleteTranscriptTerm(term.id) }, secondaryButton: .cancel(Text(store.t("إلغاء", "Cancel"))))
        }
    }
}

private struct TranscriptResultRoute: Identifiable { let id = UUID(); let result: TranscriptTerm.Result }

struct TranscriptTermEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var term: TranscriptTerm
    var isNew = false
    @State private var resultRoute: TranscriptResultRoute?
    var body: some View {
        Form {
            Section(header: Text(store.t("بيانات الفصل", "Term information"))) {
                TextField(store.t("اسم الفصل", "Term name"), text: $term.title)
                TextField(store.t("الساعات", "Credits"), value: $term.hours, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
                TextField(store.t("المعدل الفصلي", "Term GPA"), value: $term.termGPA, formatter: NumberFormatter.masariDecimal).keyboardType(.decimalPad)
                TextField(store.t("المعدل التراكمي", "Cumulative GPA"), value: $term.cumulativeGPA, formatter: NumberFormatter.masariDecimal).keyboardType(.decimalPad)
            }
            Section(header: Text(store.t("المواد والدرجات", "Courses and grades"))) {
                ForEach(term.results) { result in
                    HStack { VStack(alignment: .leading) { Text(result.name); Text("\(result.code) • \(result.grade)").font(.caption).foregroundColor(.secondary) }; Spacer(); Button { resultRoute = TranscriptResultRoute(result: result) } label: { Image(systemName: "pencil.circle.fill") }; Button { term.results.removeAll { $0.id == result.id } } label: { Image(systemName: "trash.circle.fill").foregroundColor(.red) } }
                }
                Button { resultRoute = TranscriptResultRoute(result: .init(code: "", name: "", credits: 3, grade: "", points: 0)) } label: { Label(store.t("إضافة مادة ودرجة", "Add course result"), systemImage: "plus.circle.fill") }
            }
        }
        .navigationTitle(isNew ? store.t("إضافة فصل", "Add term") : store.t("تعديل الفصل", "Edit term"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button(store.t("إلغاء", "Cancel")) { presentationMode.wrappedValue.dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) { Button(store.t("حفظ", "Save")) { if isNew { store.addTranscriptTerm(term) } else { store.updateTranscriptTerm(term) }; presentationMode.wrappedValue.dismiss() }.disabled(term.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }
        .sheet(item: $resultRoute) { route in NavigationView { TranscriptResultEditor(result: route.result) { updated in if let index = term.results.firstIndex(where: { $0.id == updated.id }) { term.results[index] = updated } else { term.results.append(updated) } } }.navigationViewStyle(StackNavigationViewStyle()) }
        .keyboardDismissOnTapAndDrag()
    }
}

struct TranscriptResultEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var result: TranscriptTerm.Result
    let onSave: (TranscriptTerm.Result) -> Void
    var body: some View {
        Form {
            TextField(store.t("رمز المادة", "Course code"), text: $result.code); TextField(store.t("اسم المادة", "Course name"), text: $result.name)
            TextField(store.t("الساعات", "Credits"), value: $result.credits, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
            TextField(store.t("التقدير", "Grade"), text: $result.grade); TextField(store.t("النقاط", "Points"), value: $result.points, formatter: NumberFormatter.masariDecimal).keyboardType(.decimalPad)
        }
        .navigationTitle(store.t("بيانات النتيجة", "Result details"))
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(store.t("إلغاء", "Cancel")) { presentationMode.wrappedValue.dismiss() } }; ToolbarItem(placement: .navigationBarTrailing) { Button(store.t("حفظ", "Save")) { onSave(result); presentationMode.wrappedValue.dismiss() }.disabled(result.code.isEmpty || result.name.isEmpty) } }
        .keyboardDismissOnTapAndDrag()
    }
}

struct SearchView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""

    private var matchingCourses: [Course] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return store.courses }
        return store.courses.filter { $0.code.localizedCaseInsensitiveContains(clean) || $0.nameAR.localizedCaseInsensitiveContains(clean) || $0.nameEN.localizedCaseInsensitiveContains(clean) }
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                LazyVStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(AppTheme.primary)
                        TextField("ابحث عن مادة أو رمز مقرر", text: $query)
                    }.padding().background(RoundedRectangle(cornerRadius: 17).fill(Color(.secondarySystemBackground)))
                    ForEach(matchingCourses) { course in
                        NavigationLink(destination: course.status == .current ? AnyView(CourseDetailView(courseID: course.id)) : AnyView(PlanView())) {
                            SectionCard { CourseRow(course: course) }
                        }.buttonStyle(PlainButtonStyle())
                    }
                }.padding()
            }.keyboardDismissOnTapAndDrag()
        }
        .navigationTitle("البحث")
    }
}

struct SupportView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    RaedLogoView(size: 92)
                    Text("دعم طلاب AEC").font(.title2.bold())
                    Text("نساعدك في تسجيل الدخول، استعادة الحساب، ملاحظات التطبيق والمشكلات التقنية.")
                        .foregroundColor(.secondary).multilineTextAlignment(.center)
                    SectionCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Link(destination: URL(string: "mailto:info@abofahad.net")!) {
                                Label("info@abofahad.net", systemImage: "envelope.fill")
                            }
                            Divider()
                            Link(destination: URL(string: "https://portal.arabeast.edu.sa")!) {
                                Label("فتح البوابة الأكاديمية", systemImage: "safari.fill")
                            }
                            Divider()
                            Link(destination: URL(string: "https://lms.arabeast.edu.sa")!) {
                                Label("فتح نظام LMS", systemImage: "graduationcap.fill")
                            }
                        }.font(.headline).foregroundColor(AppTheme.primary)
                    }
                    Text("تم تصميم هذا التطبيق بشكل فردي ولا يمثل كليات الشرق العربي")
                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.padding(22)
            }
        }.navigationTitle("الدعم")
    }
}

private struct EventEditRoute: Identifiable {
    let id = UUID()
    let event: AcademicEvent
    let isNew: Bool
}

struct NotificationCenterView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editRoute: EventEditRoute?
    @State private var pendingDelete: AcademicEvent?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                LazyVStack(spacing: 13) {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("تنبيهات المحاضرات", systemImage: "bell.badge.fill").font(.headline)
                            Picker("التنبيه قبل المحاضرة", selection: $store.settings.lectureReminderMinutes) {
                                Text("5 دقائق").tag(5); Text("10 دقائق").tag(10); Text("15 دقيقة").tag(15)
                                Text("30 دقيقة").tag(30); Text("ساعة").tag(60)
                            }
                            Button { NotificationManager.shared.refresh(store: store) } label: {
                                Label("تفعيل وتحديث التنبيهات", systemImage: "checkmark.circle.fill")
                            }.font(.caption.bold()).foregroundColor(AppTheme.primary)
                        }
                    }

                    if store.upcomingEvents.isEmpty {
                        SectionCard {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.plus").font(.largeTitle).foregroundColor(AppTheme.primary)
                                Text("لا توجد تسليمات أو اختبارات قادمة").font(.headline)
                                Text("أضف موعدًا وسيصلك إشعار قبل الوقت الذي تحدده.").font(.caption).foregroundColor(.secondary)
                            }.frame(maxWidth: .infinity)
                        }
                    }

                    ForEach(store.upcomingEvents) { event in
                        SectionCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    EventCompactRow(event: event)
                                    EditDeleteButtons(edit: { editRoute = EventEditRoute(event: event, isNew: false) }, delete: { pendingDelete = event })
                                }
                                Divider()
                                HStack {
                                    Label(event.dueDate.formattedAEC, systemImage: "calendar")
                                    Spacer()
                                    Label("قبل \(event.reminderMinutes) دقيقة", systemImage: "bell")
                                }.font(.caption).foregroundColor(.secondary)
                                if !event.details.isEmpty { Text(event.details).font(.caption).foregroundColor(.secondary) }
                            }
                        }
                    }
                }.padding()
            }.keyboardDismissOnTapAndDrag()
        }
        .navigationTitle("التنبيهات والمواعيد")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editRoute = EventEditRoute(event: AcademicEvent(title: "", details: "", dueDate: Date().addingTimeInterval(86_400), kind: .assignment, courseCode: "", reminderMinutes: store.settings.eventReminderMinutes), isNew: true)
                } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(item: $editRoute) { route in
            NavigationView { AcademicEventEditor(event: route.event, isNew: route.isNew) }.navigationViewStyle(StackNavigationViewStyle())
        }
        .alert(item: $pendingDelete) { event in
            Alert(title: Text("حذف الموعد؟"), message: Text(event.title), primaryButton: .destructive(Text("حذف")) { store.deleteEvent(event.id) }, secondaryButton: .cancel(Text("إلغاء")))
        }
        .onChange(of: store.settings.lectureReminderMinutes) { _ in store.save(); NotificationManager.shared.scheduleLectures(store: store) }
    }
}

struct AcademicEventEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var event: AcademicEvent
    let isNew: Bool

    var body: some View {
        Form {
            Section(header: Text("تفاصيل الموعد")) {
                Picker("النوع", selection: $event.kind) {
                    Text("تسليم").tag(AcademicEventKind.assignment)
                    Text("اختبار").tag(AcademicEventKind.exam)
                }
                TextField("اسم التسليم أو الاختبار", text: $event.title)
                Picker("المادة", selection: $event.courseCode) {
                    Text("بدون مادة محددة").tag("")
                    ForEach(store.courses.filter { $0.status == .current }) { course in Text("\(course.code) — \(course.nameAR)").tag(course.code) }
                }
                DatePicker("التاريخ والوقت", selection: $event.dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                Picker("التنبيه قبل الموعد", selection: $event.reminderMinutes) {
                    Text("15 دقيقة").tag(15); Text("30 دقيقة").tag(30); Text("ساعة").tag(60)
                    Text("3 ساعات").tag(180); Text("يوم").tag(1_440)
                }
                TextField("ملاحظات أو تعليمات", text: $event.details)
            }
        }
        .navigationTitle(isNew ? "إضافة موعد" : "تعديل الموعد")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button("إلغاء") { presentationMode.wrappedValue.dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("حفظ") {
                    if isNew { store.addEvent(event) } else { store.updateEvent(event) }
                    store.settings.eventReminderMinutes = event.reminderMinutes; store.save()
                    presentationMode.wrappedValue.dismiss()
                }.disabled(event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .keyboardDismissOnTapAndDrag()
    }
}

private extension Date {
    var formattedAEC: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
