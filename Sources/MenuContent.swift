import SwiftUI
import AppKit

struct MenuContent: View {
    @EnvironmentObject var monitor: AssertionMonitor
    @EnvironmentObject var ruleStore: RuleStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 440)
        .onAppear { monitor.setPopoverOpen(true) }
        .onDisappear { monitor.setPopoverOpen(false) }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: monitor.hasUserBlockers ? "moon.zzz.fill" : "moon.zzz")
            Text("Sleep Blockers").font(.headline)
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text("Idle \(formatIdle(IdleMonitor.secondsIdle()))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .help("Time since your last keyboard or mouse input. Rules with an idle threshold fire when this exceeds the threshold.")
            }
            Button {
                monitor.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if monitor.hasUserBlockers {
            blockersList(monitor.userBlockers, maxBeforeScroll: 6, scrollHeight: 540)
        } else {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.green)
                Text("Nothing is blocking sleep").font(.callout)
                Text("Your Mac can sleep when idle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }

        if monitor.showAll && !monitor.visibleOther.isEmpty {
            Divider()
            Text("Other (system / non-blocking)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 8)
            blockersList(monitor.visibleOther, maxBeforeScroll: 4, scrollHeight: 260)
        }
    }

    @ViewBuilder
    private func blockersList(_ list: [AssertionGroup], maxBeforeScroll: Int, scrollHeight: CGFloat) -> some View {
        let rows = VStack(spacing: 0) {
            ForEach(list) { a in
                AssertionRow(group: a)
                Divider()
            }
        }
        if list.count > maxBeforeScroll {
            ScrollView { rows }
                .frame(height: scrollHeight)
        } else {
            rows
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle("Show all", isOn: $monitor.showAll)
                .toggleStyle(.switch)
                .controlSize(.mini)
            Spacer()
            Button {
                Actions.forceSleep()
            } label: {
                Label("Sleep Now", systemImage: "moon.fill")
            }
            .help("Put the Mac to sleep immediately, ignoring all assertions.")
            Button("Rules…") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "rules")
            }
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .font(.caption)
    }

    private func formatIdle(_ t: TimeInterval) -> String {
        let s = Int(t)
        if s < 60 { return "\(s)s" }
        let m = s / 60, r = s % 60
        if m < 60 { return "\(m)m \(r)s" }
        let h = m / 60, mr = m % 60
        return "\(h)h \(mr)m"
    }
}
