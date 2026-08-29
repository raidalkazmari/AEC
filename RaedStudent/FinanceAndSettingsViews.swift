import SwiftUI
import UniformTypeIdentifiers

private struct PaymentEditRoute: Identifiable { let id = UUID(); let payment: PaymentRecord; let isNew: Bool }

struct FinanceView: View {
    @EnvironmentObject private var store: AppStore
    @State private var paymentRoute: PaymentEditRoute?
    @State private var pendingDelete: PaymentRecord?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 14) {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(store.t("تكلفة الساعة", "Cost per credit")).font(.caption).foregroundColor(.secondary)
                            Text(store.hourCost.sar).font(.largeTitle.bold()).foregroundColor(AppTheme.deepTeal)
                            Text(store.t("يتم حساب تكلفة الفصل تلقائيًا: عدد الساعات × 1,150 ريال", "Term cost is calculated automatically: credits × SAR 1,150"))
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        StatCard(title: store.t("إجمالي المدفوع", "Total paid"), value: store.paidTotal.sar, icon: "checkmark.circle.fill", color: AppTheme.success)
                        StatCard(title: store.t("إجمالي المتبقي", "Total remaining"), value: store.remainingTotal.sar, icon: "clock.fill", color: .orange)
                    }
                    ForEach(store.payments) { payment in
                        SectionCard { VStack(alignment: .leading, spacing: 10) {
                            HStack { Text(payment.term).font(.headline); Spacer(); PaymentPill(status: payment.status); EditDeleteButtons(edit: { paymentRoute = PaymentEditRoute(payment: payment, isNew: false) }, delete: { pendingDelete = payment }) }
                            ProgressView(value: payment.amount == 0 ? 0 : payment.paidAmount / payment.amount).accentColor(AppTheme.success)
                            HStack { Text(store.t("دُفع: \(payment.paidAmount.sar)", "Paid: \(payment.paidAmount.sar)")); Spacer(); Text(store.t("المبلغ: \(payment.amount.sar)", "Amount: \(payment.amount.sar)")) }.font(.caption).foregroundColor(.secondary)
                            if let hours = payment.creditHours { Text(store.t("\(hours) ساعة × 1,150 ريال", "\(hours) credits × SAR 1,150")).font(.caption2).foregroundColor(.secondary) }
                            if !payment.note.isEmpty { Text(payment.note).font(.caption2).foregroundColor(.secondary) }
                        } }
                    }
                    Button { paymentRoute = PaymentEditRoute(payment: PaymentRecord(term: "", amount: 0, paidAmount: 0, status: .due, note: ""), isNew: true) } label: { Label(store.t("إضافة دفعة", "Add payment"), systemImage: "plus.circle.fill").frame(maxWidth: .infinity).padding() }
                        .buttonStyle(PrimaryButtonStyle())
                }.padding()
            }.keyboardDismissOnTapAndDrag()
        }
        .navigationTitle(store.t("السجل المالي", "Financial record"))
        .sheet(item: $paymentRoute) { route in NavigationView { PaymentEditor(payment: route.payment, isNew: route.isNew) }.navigationViewStyle(StackNavigationViewStyle()) }
        .alert(item: $pendingDelete) { payment in Alert(title: Text(store.t("حذف السجل المالي؟", "Delete payment record?")), message: Text(payment.term), primaryButton: .destructive(Text(store.t("حذف", "Delete"))) { store.deletePayment(payment.id) }, secondaryButton: .cancel(Text(store.t("إلغاء", "Cancel")))) }
    }
}

private struct PaymentPill: View {
    @EnvironmentObject private var store: AppStore
    let status: PaymentStatus
    var body: some View {
        Text(label).font(.caption2.bold()).padding(.horizontal, 9).padding(.vertical, 5).background(Capsule().fill(color.opacity(0.16))).foregroundColor(color)
    }
    private var color: Color { status == .paid ? AppTheme.success : (status == .partial ? .orange : .red) }
    private var label: String {
        switch status { case .paid: store.t("مدفوع", "Paid"); case .due: store.t("متبقٍ", "Due"); case .partial: store.t("جزئي", "Partial") }
    }
}

struct PaymentEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var payment: PaymentRecord
    var isNew = false
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section(header: Text(store.t("بيانات الفصل", "Term information"))) {
                LabeledTextField(title: store.t("اسم الفصل", "Term name"), placeholder: store.t("مثال: الفصل 472", "Example: Term 472"), text: $payment.term)
                VStack(alignment: .leading, spacing: 7) {
                    Text(store.t("عدد الساعات (اختياري)", "Credit hours (optional)")).font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    TextField("0", value: $payment.creditHours, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad).padding(11).background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemBackground)))
                    Button { if let hours = payment.creditHours { payment.amount = Double(hours) * store.hourCost } } label: { Label(store.t("احسب المستحق: الساعات × 1,150", "Calculate: credits × 1,150"), systemImage: "equal.circle.fill") }.disabled(payment.creditHours == nil)
                }.padding(.vertical, 3)
            }
            Section(header: Text(store.t("المبالغ", "Amounts")), footer: Text(store.t("اكتب المبلغ بالأرقام فقط، مثال: 20700", "Enter numbers only, example: 20700"))) {
                PaymentNumberField(title: store.t("إجمالي المبلغ المستحق", "Total amount due"), value: $payment.amount)
                PaymentNumberField(title: store.t("المبلغ الذي دفعته", "Amount paid"), value: $payment.paidAmount)
            }
            Section(header: Text(store.t("الحالة والملاحظة", "Status and note"))) {
                Picker(store.t("الحالة", "Status"), selection: $payment.status) {
                    Text(store.t("مدفوع", "Paid")).tag(PaymentStatus.paid)
                    Text(store.t("متبقٍ", "Due")).tag(PaymentStatus.due)
                    Text(store.t("جزئي", "Partial")).tag(PaymentStatus.partial)
                }
                LabeledTextField(title: store.t("ملاحظة", "Note"), placeholder: store.t("أي تفاصيل إضافية", "Any extra details"), text: $payment.note)
            }
            Section {
                if !isNew { Button { showDeleteAlert = true } label: { Label(store.t("حذف هذه الدفعة", "Delete this payment"), systemImage: "trash.fill").foregroundColor(.red) } }
            }
        }
        .navigationTitle(isNew ? store.t("إضافة دفعة", "Add payment") : store.t("تعديل الدفعة", "Edit payment"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button(store.t("إلغاء", "Cancel")) { presentationMode.wrappedValue.dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(store.t("حفظ", "Save")) {
                    UIApplication.shared.dismissKeyboard()
                    payment.amount = max(payment.amount, 0); payment.paidAmount = min(max(payment.paidAmount, 0), payment.amount)
                    payment.status = payment.paidAmount >= payment.amount && payment.amount > 0 ? .paid : (payment.paidAmount > 0 ? .partial : .due)
                    if isNew { store.addPayment(payment) } else { store.updatePayment(payment) }
                    presentationMode.wrappedValue.dismiss()
                }.disabled(payment.term.isEmpty)
            }
        }
        .alert(isPresented: $showDeleteAlert) { Alert(title: Text(store.t("حذف الدفعة؟", "Delete payment?")), primaryButton: .destructive(Text(store.t("حذف", "Delete"))) { store.deletePayment(payment.id); presentationMode.wrappedValue.dismiss() }, secondaryButton: .cancel(Text(store.t("إلغاء", "Cancel")))) }
        .keyboardDismissOnTapAndDrag()
        .onChange(of: payment.creditHours) { hours in
            if let hours { payment.amount = Double(max(hours, 0)) * store.hourCost }
        }
    }
}

private struct PaymentNumberField: View {
    let title: String
    @Binding var value: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            HStack { TextField("0", value: $value, formatter: NumberFormatter.masariDecimal).keyboardType(.decimalPad); Text("ر.س").foregroundColor(.secondary) }
                .padding(11).background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemBackground))).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator).opacity(0.35)))
        }.padding(.vertical, 3)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var editing = false
    @State private var draft: StudentProfile?
    @State private var revealNationalID = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 15) {
                    RaedLogoView(size: 92)
                    Text(store.profile.arabicName).font(.title3.bold()).multilineTextAlignment(.center)
                    Text(store.profile.studentID).font(.system(.subheadline, design: .monospaced)).foregroundColor(AppTheme.teal)
                    SectionCard {
                        VStack(spacing: 12) {
                            row(store.t("الكلية", "College"), store.profile.college)
                            row(store.t("التخصص", "Major"), store.profile.major)
                            row(store.t("الدرجة", "Degree"), store.profile.degree)
                            row(store.t("نوع الدراسة", "Study type"), store.profile.studyType)
                            row(store.t("الهوية الوطنية", "National ID"), revealNationalID ? store.profile.nationalID : "••••••\(store.profile.nationalID.suffix(4))", action: { revealNationalID.toggle() })
                            row(store.t("البريد الجامعي", "University email"), store.profile.universityEmail.isEmpty ? store.t("غير مضاف", "Not added") : store.profile.universityEmail)
                            row(store.t("الجوال", "Phone"), store.profile.phone)
                            row(store.t("المرشد الأكاديمي", "Academic advisor"), store.profile.academicAdvisor)
                        }
                    }
                    Button { draft = store.profile; editing = true } label: { Label(store.t("تعديل بياناتي", "Edit profile"), systemImage: "pencil").frame(maxWidth: .infinity).padding() }
                        .buttonStyle(PrimaryButtonStyle())
                }.padding()
            }
        }
        .navigationTitle(store.t("بيانات الطالب", "Student profile"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { NavigationLink(destination: SettingsView()) { Image(systemName: "gearshape.fill") } }
            ToolbarItem(placement: .navigationBarTrailing) { Button(store.t("تم", "Done")) { presentationMode.wrappedValue.dismiss() } }
        }
        .sheet(isPresented: $editing) { if let draft { NavigationView { ProfileEditor(profile: draft) }.navigationViewStyle(StackNavigationViewStyle()) } }
    }

    private func row(_ title: String, _ value: String, action: (() -> Void)? = nil) -> some View {
        HStack(alignment: .top) {
            Text(title).font(.caption).foregroundColor(.secondary).frame(width: 105, alignment: .leading)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).multilineTextAlignment(.trailing)
            if let action { Button(action: action) { Image(systemName: revealNationalID ? "eye.slash" : "eye") } }
        }
    }
}

struct ProfileEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var profile: StudentProfile

    var body: some View {
        Form {
            Section(header: Text(store.t("البيانات الشخصية", "Personal information"))) {
                TextField(store.t("الاسم", "Name"), text: $profile.arabicName)
                TextField(store.t("الاسم بالإنجليزية", "English name"), text: $profile.englishName)
                TextField(store.t("الرقم الجامعي", "Student ID"), text: $profile.studentID)
                TextField(store.t("الهوية الوطنية", "National ID"), text: $profile.nationalID)
                TextField(store.t("رقم الجوال", "Phone"), text: $profile.phone)
                TextField(store.t("البريد الجامعي", "University email"), text: $profile.universityEmail).autocapitalization(.none)
                TextField(store.t("البريد الشخصي", "Personal email"), text: $profile.personalEmail).autocapitalization(.none)
            }
            Section(header: Text(store.t("البيانات الأكاديمية", "Academic information"))) {
                TextField(store.t("الكلية", "College"), text: $profile.college)
                TextField(store.t("التخصص", "Major"), text: $profile.major)
                TextField(store.t("الدرجة", "Degree"), text: $profile.degree)
                TextField(store.t("نوع الدراسة", "Study type"), text: $profile.studyType)
                TextField(store.t("إجمالي ساعات الخطة", "Plan credits"), value: $profile.planHours, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
                TextField(store.t("الساعات المجتازة", "Completed credits"), value: $profile.completedHours, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
                TextField(store.t("الساعات الحالية", "Current credits"), value: $profile.currentHours, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
                TextField(store.t("المعدل", "GPA"), value: $profile.gpa, formatter: NumberFormatter.masariDecimal).keyboardType(.decimalPad)
                TextField(store.t("المتبقي رسميًا", "Official remaining"), value: $profile.officialRemainingOverride, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
                TextField(store.t("المتبقي بعد الفصل", "Remaining after term"), value: $profile.expectedRemainingAfterCurrentOverride, formatter: NumberFormatter.masariInteger).keyboardType(.numberPad)
            }
        }
        .navigationTitle(store.t("تعديل بياناتي", "Edit profile"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button(store.t("إلغاء", "Cancel")) { presentationMode.wrappedValue.dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) { Button(store.t("حفظ", "Save")) { store.profile = profile; store.save(); presentationMode.wrappedValue.dismiss() } }
        }
        .keyboardDismissOnTapAndDrag()
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var openAIKey = KeychainService.load(key: "openai-api-key") ?? ""
    @State private var geminiKey = KeychainService.load(key: "gemini-api-key") ?? ""
    @State private var keySaved = false
    @State private var importingSound = false
    @State private var soundMessage: String?
    @State private var changePINVisible = false
    var body: some View {
        Form {
            Section(header: Text(store.t("الحساب", "Account"))) {
                HStack { Text(store.t("الرقم الجامعي", "Student ID")); Spacer(); Text(store.currentAccount?.studentID ?? store.profile.studentID).foregroundColor(.secondary) }
                HStack { Text(store.t("البريد الجامعي", "University email")); Spacer(); Text(store.currentAccount?.email ?? store.profile.universityEmail).foregroundColor(.secondary).lineLimit(1).minimumScaleFactor(0.65) }
                Button { changePINVisible = true } label: { Label(store.t("تغيير الرقم السري", "Change password"), systemImage: "lock.rotation") }
            }
            Section(header: Text(store.t("التطبيق", "Application"))) {
                Picker(store.t("اللغة", "Language"), selection: $store.settings.language) { Text("العربية").tag(AppLanguage.arabic); Text("English").tag(AppLanguage.english) }
                Picker(store.t("المظهر", "Theme"), selection: $store.settings.theme) { Text(store.t("حسب الجهاز", "System")).tag(AppThemeMode.system); Text(store.t("فاتح", "Light")).tag(AppThemeMode.light); Text(store.t("داكن", "Dark")).tag(AppThemeMode.dark) }
            }
            Section(header: Text(store.t("نغمة بدء التشغيل", "Startup chime"))) {
                Toggle(store.t("تشغيل النغمة", "Play startup chime"), isOn: $store.settings.startupSound)
                Picker(store.t("نوع النغمة", "Tone"), selection: $store.settings.startupTone) { Text(store.t("الاحترافية", "Classic")).tag(StartupTone.classic); Text(store.t("الهادئة", "Soft")).tag(StartupTone.soft); Text(store.t("المشرقة", "Bright")).tag(StartupTone.bright); Text(store.t("من ملفاتي", "Custom file")).tag(StartupTone.custom) }
                Button { importingSound = true } label: { Label(store.t("اختيار نغمة من تطبيق الملفات", "Choose sound from Files"), systemImage: "folder.fill") }
                Button { StartupChime.shared.play(tone: store.settings.startupTone, customURL: store.customStartupSoundURL) } label: { Label(store.t("تجربة النغمة", "Preview sound"), systemImage: "play.circle.fill") }
                if let soundMessage { Text(soundMessage).font(.caption).foregroundColor(.secondary) }
            }
            Section(header: Text(store.t("التنبيهات", "Notifications"))) {
                Picker(store.t("قبل المحاضرة", "Before lecture"), selection: $store.settings.lectureReminderMinutes) {
                    Text(store.t("5 دقائق", "5 minutes")).tag(5); Text(store.t("10 دقائق", "10 minutes")).tag(10)
                    Text(store.t("15 دقيقة", "15 minutes")).tag(15); Text(store.t("30 دقيقة", "30 minutes")).tag(30); Text(store.t("ساعة", "1 hour")).tag(60)
                }
                Button { NotificationManager.shared.refresh(store: store) } label: { Label(store.t("تفعيل التنبيهات", "Enable notifications"), systemImage: "bell.badge.fill") }
            }
            Section(header: Text(store.t("الذكاء الاصطناعي", "Artificial intelligence"))) {
                Picker(store.t("الخدمة", "Provider"), selection: $store.settings.aiProvider) { Text("Google Gemini — مجاني").tag(AIProvider.gemini); Text("OpenAI — مدفوع").tag(AIProvider.openAI) }
                if store.settings.aiProvider == .gemini {
                    SecureField("Gemini API Key", text: $geminiKey).autocapitalization(.none).disableAutocorrection(true)
                    Picker(store.t("النموذج", "Model"), selection: $store.settings.geminiModel) {
                        Text("Gemini 3.5 Flash Lite — مجاني واقتصادي").tag("gemini-3.5-flash-lite")
                        Text("Gemini 3.7 Flash — أقوى").tag("gemini-3.7-flash")
                    }
                    Text(store.t("احصل على مفتاح مجاني من Google AI Studio، ثم الصقه هنا واحفظه.", "Get a free key from Google AI Studio, paste it here, then save it.")).font(.caption).foregroundColor(.secondary)
                    Link(destination: URL(string: "https://aistudio.google.com/apikey")!) { Label(store.t("فتح Google AI Studio", "Open Google AI Studio"), systemImage: "safari.fill") }
                } else {
                    SecureField("OpenAI API Key", text: $openAIKey).autocapitalization(.none).disableAutocorrection(true)
                    Picker(store.t("النموذج", "Model"), selection: $store.settings.aiModel) { Text("GPT-5.6 Luna — اقتصادي").tag("gpt-5.6-luna"); Text("GPT-5.6 Terra — متوازن").tag("gpt-5.6-terra"); Text("GPT-5.6 Sol — الأقوى").tag("gpt-5.6-sol") }
                }
                Button { saveCurrentKey() } label: { Label(keySaved ? store.t("تم حفظ المفتاح", "Key saved") : store.t("حفظ المفتاح بأمان", "Save key securely"), systemImage: keySaved ? "checkmark.circle.fill" : "key.fill") }
            }
            Section { Button { deleteCurrentKey() } label: { Text(store.t("حذف مفتاح الخدمة الحالية", "Delete current provider key")).foregroundColor(.red) } }
            Section {
                Button {
                    UIApplication.shared.dismissKeyboard(); store.logout(); presentationMode.wrappedValue.dismiss()
                } label: { Label(store.t("تسجيل الخروج", "Sign out"), systemImage: "rectangle.portrait.and.arrow.right").foregroundColor(.red) }
            }
        }
        .navigationTitle(store.t("الإعدادات", "Settings"))
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(store.t("تم", "Done")) { UIApplication.shared.dismissKeyboard(); store.save(); presentationMode.wrappedValue.dismiss() } } }
        .fileImporter(isPresented: $importingSound, allowedContentTypes: [.audio]) { result in
            switch result { case .success(let url): soundMessage = store.importStartupSound(from: url) ? store.t("تم اعتماد النغمة الجديدة", "Custom sound selected") : store.t("تعذر استيراد الملف", "Could not import file"); case .failure(_): soundMessage = store.t("لم يتم اختيار ملف", "No file selected") }
        }
        .sheet(isPresented: $changePINVisible) { NavigationView { ChangePINView() }.navigationViewStyle(StackNavigationViewStyle()) }
        .keyboardDismissOnTapAndDrag()
        .onChange(of: store.settings.language) { _ in store.save() }.onChange(of: store.settings.theme) { _ in store.save() }.onChange(of: store.settings.startupSound) { _ in store.save() }.onChange(of: store.settings.startupTone) { _ in store.save() }.onChange(of: store.settings.aiProvider) { _ in keySaved = false; store.save() }.onChange(of: store.settings.aiModel) { _ in store.save() }.onChange(of: store.settings.geminiModel) { _ in store.save() }.onChange(of: store.settings.lectureReminderMinutes) { _ in store.save(); NotificationManager.shared.scheduleLectures(store: store) }
    }
    private func saveCurrentKey() {
        UIApplication.shared.dismissKeyboard()
        if store.settings.aiProvider == .gemini { let clean = geminiKey.trimmingCharacters(in: .whitespacesAndNewlines); if clean.isEmpty { KeychainService.delete(key: "gemini-api-key") } else { KeychainService.save(clean, key: "gemini-api-key") } }
        else { let clean = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines); if clean.isEmpty { KeychainService.delete(key: "openai-api-key") } else { KeychainService.save(clean, key: "openai-api-key") } }
        keySaved = true; store.save()
    }
    private func deleteCurrentKey() { if store.settings.aiProvider == .gemini { KeychainService.delete(key: "gemini-api-key"); geminiKey = "" } else { KeychainService.delete(key: "openai-api-key"); openAIKey = "" }; keySaved = true }
}

struct ChangePINView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var message: String?

    var body: some View {
        Form {
            Section(header: Text("الرقم السري"), footer: Text("استخدم من 1 إلى 8 أرقام.")) {
                SecureField("الرقم السري الحالي", text: $currentPIN).keyboardType(.numberPad)
                SecureField("الرقم السري الجديد", text: $newPIN).keyboardType(.numberPad)
                SecureField("تأكيد الرقم السري", text: $confirmPIN).keyboardType(.numberPad)
            }
            if let message { Section { Text(message).foregroundColor(message.contains("تم") ? AppTheme.success : .red) } }
        }
        .navigationTitle("تغيير الرقم السري")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button("إلغاء") { presentationMode.wrappedValue.dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("حفظ") {
                    guard newPIN == confirmPIN else { message = "تأكيد الرقم السري غير مطابق"; return }
                    if store.updatePIN(current: currentPIN, newPIN: newPIN) {
                        message = "تم تغيير الرقم السري"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { presentationMode.wrappedValue.dismiss() }
                    } else { message = "تحقق من الرقم الحالي وأن الجديد من 1 إلى 8 أرقام" }
                }.disabled(newPIN.isEmpty || confirmPIN.isEmpty)
            }
        }
        .keyboardDismissOnTapAndDrag()
        .onChange(of: currentPIN) { currentPIN = String($0.filter { $0.isNumber }.prefix(8)) }
        .onChange(of: newPIN) { newPIN = String($0.filter { $0.isNumber }.prefix(8)) }
        .onChange(of: confirmPIN) { confirmPIN = String($0.filter { $0.isNumber }.prefix(8)) }
    }
}
