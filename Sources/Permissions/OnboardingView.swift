import SwiftUI

struct OnboardingView: View {
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("SlowTV Controller needs Accessibility access")
                .font(.headline)

            Text("This lets SlowTV Controller move your cursor and inject clicks/keys from your controller.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Label("Open System Settings → Privacy & Security → Accessibility", systemImage: "1.circle")
                Label("Find SlowTV Controller in the list and toggle it on", systemImage: "2.circle")
                Label("This window will close automatically", systemImage: "3.circle")
            }
            .font(.callout)
            .padding(.horizontal)

            Button("Open Accessibility Settings") {
                onOpenSettings()
            }
            .buttonStyle(.borderedProminent)

            Text("Waiting for permission...")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(30)
        .frame(width: 400, height: 300)
    }
}
