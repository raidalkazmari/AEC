import SwiftUI

@main
struct RaedStudentApp: App {
    @StateObject private var store = AppStore()
    @State private var splashVisible = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if store.isAuthenticated { MainTabView() }
                    else { LoginView() }
                }
                .opacity(splashVisible ? 0 : 1)

                if splashVisible {
                    SplashView().transition(.opacity.combined(with: .scale(scale: 1.02)))
                }
            }
            .environmentObject(store)
            .environment(\.layoutDirection, store.settings.language == .arabic ? .rightToLeft : .leftToRight)
            .preferredColorScheme(store.settings.theme.colorScheme)
            .onAppear {
                if store.settings.startupSound {
                    StartupChime.shared.play(tone: store.settings.startupTone, customURL: store.customStartupSoundURL)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
                    withAnimation(.easeInOut(duration: 0.35)) { splashVisible = false }
                }
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var store: AppStore
    @State private var studentID = ""
    @State private var pin = ""
    @State private var rememberMe = true
    @State private var errorText: String?
    @State private var forgotVisible = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.navy, AppTheme.deepBlue, AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Circle().fill(AppTheme.cyan.opacity(0.20)).frame(width: 330, height: 330).blur(radius: 30).offset(x: -150, y: -310)
            Circle().fill(AppTheme.violet.opacity(0.18)).frame(width: 280, height: 280).blur(radius: 35).offset(x: 170, y: 330)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 34)
                    VStack(spacing: 13) {
                        RaedLogoView(size: 104).shadow(color: .black.opacity(0.25), radius: 26, y: 14)
                        Text("طلاب AEC")
                            .font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundColor(.white)
                        Text("بوابتك الأكاديمية الذكية")
                            .font(.subheadline.weight(.medium)).foregroundColor(.white.opacity(0.72))
                    }

                    VStack(spacing: 16) {
                        LoginField(title: "الرقم الجامعي", icon: "person.text.rectangle", text: $studentID, secure: false)
                        LoginField(title: "الرقم السري", icon: "lock.fill", text: $pin, secure: true)

                        Toggle(isOn: $rememberMe) {
                            Label("تذكرني", systemImage: "checkmark.shield.fill").font(.subheadline.weight(.semibold))
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.primary))

                        if let errorText {
                            Label(errorText, systemImage: "exclamationmark.circle.fill")
                                .font(.caption.weight(.semibold)).foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: signIn) {
                            HStack {
                                Text("تسجيل الدخول").font(.headline)
                                Image(systemName: "arrow.left.circle.fill").font(.title3)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                        }
                        .buttonStyle(PrimaryButtonStyle(color: AppTheme.primary))

                        Button { forgotVisible = true } label: {
                            Text("نسيت كلمة السر؟").font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(PlainButtonStyle()).foregroundColor(AppTheme.primary)

                        Text("الرقم السري المبدئي: 12345678").font(.caption2).foregroundColor(.secondary)
                    }
                    .padding(22)
                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(.systemBackground).opacity(0.96)))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.20)))
                    .shadow(color: .black.opacity(0.22), radius: 28, y: 16)

                    VStack(spacing: 8) {
                        Text("تم تصميم هذا التطبيق بشكل فردي ولا يمثل كليات الشرق العربي").multilineTextAlignment(.center)
                        Link("info@abofahad.net", destination: URL(string: "mailto:info@abofahad.net")!).fontWeight(.bold)
                    }
                    .font(.caption).foregroundColor(.white.opacity(0.72))
                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 22)
            }
        }
        .keyboardDismissOnTapAndDrag()
        .sheet(isPresented: $forgotVisible) {
            NavigationView { ForgotPasswordView(studentID: studentID) }.navigationViewStyle(StackNavigationViewStyle())
        }
        .onChange(of: studentID) { value in studentID = String(value.filter { $0.isNumber }.prefix(12)) }
        .onChange(of: pin) { value in pin = String(value.filter { $0.isNumber }.prefix(8)) }
    }

    private func signIn() {
        UIApplication.shared.dismissKeyboard()
        guard (1...8).contains(pin.count) else {
            errorText = "الرقم السري يجب أن يكون من 1 إلى 8 أرقام"
            return
        }
        switch store.login(studentID: studentID, password: pin, remember: rememberMe) {
        case .success: errorText = nil
        case .unknownStudent: errorText = "الرقم الجامعي غير موجود في قائمة الطلاب"
        case .invalidPassword: errorText = "الرقم السري غير صحيح"
        }
    }
}

private struct LoginField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let secure: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(AppTheme.primary).frame(width: 24)
            Group {
                if secure { SecureField(title, text: $text) }
                else { TextField(title, text: $text) }
            }
            .keyboardType(.numberPad)
        }
        .padding(.horizontal, 15).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primary.opacity(0.18)))
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var studentID: String
    @State private var account: StudentAccount?
    @State private var message: String?

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 18) {
                RaedLogoView(size: 84)
                Text("استعادة كلمة المرور").font(.title2.bold())
                Text("أدخل رقمك الجامعي وسيظهر بريدك الجامعي المسجل.")
                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                LoginField(title: "الرقم الجامعي", icon: "person.text.rectangle", text: $studentID, secure: false)
                if let account {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("البريد الجامعي").font(.caption).foregroundColor(.secondary)
                        Text(account.email).font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.primary.opacity(0.08)))
                }
                if let message {
                    Text(message).font(.caption.weight(.semibold)).foregroundColor(AppTheme.primary).multilineTextAlignment(.center)
                }
                Button {
                    if let found = store.resetPINToInitial(studentID: studentID) {
                        account = found
                        message = "تمت إعادة الرقم السري المبدئي إلى 12345678 لهذا الجهاز. إرسال رابط بريد تلقائي يحتاج ربط خدمة البريد بالخادم."
                    } else {
                        account = nil; message = "الرقم الجامعي غير موجود"
                    }
                } label: {
                    Label("إرسال رابط الاستعادة", systemImage: "envelope.badge.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(PrimaryButtonStyle(color: AppTheme.primary))
                Link("التواصل مع الدعم: info@abofahad.net", destination: URL(string: "mailto:info@abofahad.net")!)
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .padding(22)
        }
        .navigationTitle("نسيت كلمة السر").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("تم") { presentationMode.wrappedValue.dismiss() } } }
        .keyboardDismissOnTapAndDrag()
        .onChange(of: studentID) { value in studentID = String(value.filter { $0.isNumber }.prefix(12)) }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView {
            NavigationView { DashboardView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label(store.t("الرئيسية", "Home"), systemImage: "house.fill") }
            NavigationView { PlanView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label(store.t("الخطة", "Plan"), systemImage: "map.fill") }
            NavigationView { StudyHubView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label(store.t("دراستي", "Study"), systemImage: "books.vertical.fill") }
            NavigationView { FinanceView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label(store.t("المالية", "Finance"), systemImage: "creditcard.fill") }
            NavigationView { AIView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label(store.t("المساعد", "Assistant"), systemImage: "sparkles") }
        }
        .accentColor(AppTheme.primary)
    }
}

struct SplashView: View {
    @State private var glow = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.navy, AppTheme.deepBlue, AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            Circle().fill(AppTheme.cyan.opacity(0.16)).frame(width: glow ? 370 : 270, height: glow ? 370 : 270).blur(radius: 18)
            VStack(spacing: 22) {
                RaedLogoView(size: 144).shadow(color: .black.opacity(0.28), radius: 30, y: 18)
                VStack(spacing: 6) {
                    Text("طلاب AEC").font(.system(size: 39, weight: .heavy, design: .rounded))
                    Text("AEC STUDENTS").font(.system(size: 12, weight: .bold, design: .rounded)).tracking(5).foregroundColor(AppTheme.cyan)
                }.foregroundColor(.white)
                Text("كل دراستك في مكان واحد").font(.subheadline.weight(.medium)).foregroundColor(.white.opacity(0.72))
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) { glow = true } }
    }
}

struct RaedLogoView: View {
    var size: CGFloat = 58
    var body: some View {
        Image("StudentBrandIcon").resizable().scaledToFit().frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: size * 0.24).stroke(Color.white.opacity(0.16), lineWidth: 1))
    }
}

enum AppThemeMode: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .dark ? .dark : .light) }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case arabic, english
    var id: String { rawValue }
}

enum AppTheme {
    static let primary = Color(hex: "155EEF")
    static let deepBlue = Color(hex: "173AA7")
    static let navy = Color(hex: "08142E")
    static let cyan = Color(hex: "21C6F3")
    static let violet = Color(hex: "7A5AF8")
    static let teal = primary
    static let deepTeal = deepBlue
    static let gold = Color(hex: "F4B740")
    static let cream = Color(hex: "EEF4FF")
    static let completed = Color(hex: "1689FC")
    static let current = Color(hex: "F6C344")
    static let remaining = Color(hex: "D7DDEA")
    static let success = Color(hex: "18A875")
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var number: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&number)
        let red = Double((number >> 16) & 0xff) / 255
        let green = Double((number >> 8) & 0xff) / 255
        let blue = Double(number & 0xff) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
