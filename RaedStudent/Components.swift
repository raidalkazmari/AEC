import SwiftUI
import Foundation
import UIKit

struct AppBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(.systemBackground), AppTheme.cream.opacity(0.78), Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

struct SectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(LinearGradient(colors: [AppTheme.primary.opacity(0.20), AppTheme.cyan.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: AppTheme.navy.opacity(0.07), radius: 18, y: 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: icon).font(.title3.bold()).foregroundColor(color)
            Text(value).font(.system(.title2, design: .monospaced).bold())
            Text(title).font(.caption).foregroundColor(.secondary).lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(LinearGradient(colors: [color.opacity(0.16), color.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.12)))
    }
}

struct ProgressRing: View {
    let progress: Double
    let value: String
    let caption: String
    var body: some View {
        ZStack {
            Circle().stroke(AppTheme.teal.opacity(0.12), lineWidth: 14)
            Circle().trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AngularGradient(colors: [AppTheme.gold, AppTheme.teal], center: .center), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(value).font(.system(.title, design: .monospaced).bold())
                Text(caption).font(.caption2).foregroundColor(.secondary)
            }
        }
        .frame(width: 132, height: 132)
    }
}

struct StatusPill: View {
    @EnvironmentObject private var store: AppStore
    let status: CourseStatus
    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(Capsule().fill(status.color.opacity(0.20)))
            .foregroundColor(status == .current ? .primary : status.color)
    }
    private var label: String {
        switch status {
        case .completed: store.t("مجتاز", "Completed")
        case .current: store.t("حالي", "Current")
        case .remaining: store.t("متبقٍ", "Remaining")
        }
    }
}

struct CourseRow: View {
    @EnvironmentObject private var store: AppStore
    let course: Course
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 5).fill(course.status.color).frame(width: 7, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.courseName(course)).font(.subheadline.weight(.semibold))
                Text("\(course.code) • \(course.credits) \(store.t("ساعات", "credits"))")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            StatusPill(status: course.status)
        }
        .padding(.vertical, 6)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppTheme.teal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 13).fill(color.opacity(configuration.isPressed ? 0.76 : 1)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct LabeledTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator).opacity(0.35)))
        }.padding(.vertical, 3)
    }
}

struct EditDeleteButtons: View {
    let edit: () -> Void
    let delete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Button(action: edit) { Image(systemName: "pencil.circle.fill").foregroundColor(AppTheme.teal) }
            Button(action: delete) { Image(systemName: "trash.circle.fill").foregroundColor(.red) }
        }.font(.title3).buttonStyle(PlainButtonStyle())
    }
}

extension UIApplication {
    func dismissKeyboard() { sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
}

private struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(KeyboardDismissInstaller())
            .simultaneousGesture(DragGesture(minimumDistance: 12).onChanged { _ in UIApplication.shared.dismissKeyboard() })
    }
}

private struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async { context.coordinator.install(from: view) }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async { context.coordinator.install(from: uiView) }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) { coordinator.uninstall() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var installedView: UIView?
        private var recognizer: UITapGestureRecognizer?

        func install(from view: UIView) {
            guard recognizer == nil, let window = view.window else { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            installedView = window
            recognizer = tap
        }

        func uninstall() {
            if let recognizer { installedView?.removeGestureRecognizer(recognizer) }
            recognizer = nil
        }

        @objc private func dismissKeyboard() { installedView?.endEditing(true) }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var candidate: UIView? = touch.view
            while let view = candidate {
                if view is UITextField || view is UITextView { return false }
                candidate = view.superview
            }
            return true
        }
    }
}

extension View {
    func keyboardDismissOnTapAndDrag() -> some View { modifier(KeyboardDismissModifier()) }
}

extension Binding where Value == String {
    init(orEmpty source: Binding<String?>) {
        self.init(get: { source.wrappedValue ?? "" }, set: { source.wrappedValue = $0.isEmpty ? nil : $0 })
    }
}

extension Double {
    var sar: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))") + " ر.س"
    }
}

extension NumberFormatter {
    static let masariInteger: NumberFormatter = {
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal; formatter.maximumFractionDigits = 0; return formatter
    }()
    static let masariDecimal: NumberFormatter = {
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal; formatter.maximumFractionDigits = 2; return formatter
    }()
}
