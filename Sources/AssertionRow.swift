import SwiftUI
import AppKit

struct AssertionRow: View {
    let group: AssertionGroup
    @EnvironmentObject var ruleStore: RuleStore
    @State private var confirmingQuit = false
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                icon
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(group.displayName).fontWeight(.semibold)
                        if group.count > 1 {
                            badge("×\(group.count)", color: .blue)
                        }
                        if group.isSystemOwned {
                            badge("SYSTEM", color: .gray)
                        }
                        Spacer()
                        TimelineView(.periodic(from: .now, by: 1)) { ctx in
                            let d = group.durationOldest(at: ctx.date)
                            Text(formatDuration(d))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .help("\(group.displayName) has been blocking sleep continuously for \(formatDurationLong(d)).")
                        }
                    }
                    HStack(spacing: 6) {
                        Text(group.primaryAssertionType)
                            .font(.caption2)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(badgeColor.opacity(0.2))
                            .foregroundStyle(badgeColor)
                            .cornerRadius(3)
                        Text(AssertionInfo.severity(for: group.primaryAssertionType))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    if !group.isSystemOwned {
                        if confirmingQuit {
                            confirmBar
                        } else {
                            defaultActions
                        }
                    }
                }
            }

            if expanded {
                detail
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var subtitleText: String {
        let names = group.distinctNames
        if names.count == 1 { return names[0] }
        return "\(names.count) reasons: " + names.prefix(2).joined(separator: ", ") +
            (names.count > 2 ? ", …" : "")
    }

    @ViewBuilder
    private var icon: some View {
        if let data = group.iconData, let img = NSImage(data: data) {
            Image(nsImage: img)
                .resizable()
                .interpolation(.high)
                .frame(width: 36, height: 36)
        } else {
            Image(systemName: "app.dashed")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.secondary)
                .padding(2)
        }
    }

    private var badgeColor: Color {
        switch group.primaryAssertionType {
        case "PreventSystemSleep": return .red
        case "PreventUserIdleSystemSleep", "NoIdleSleepAssertion": return .red
        case "PreventUserIdleDisplaySleep", "NoDisplaySleepAssertion": return .orange
        default: return .gray
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 4).padding(.vertical, 1)
            .foregroundStyle(.white)
            .background(color)
            .cornerRadius(3)
    }

    private var defaultActions: some View {
        HStack(spacing: 6) {
            notifyButton
            Button("Quit") { confirmingQuit = true }
            sleepWhenIdleButton
            Spacer(minLength: 0)
            Button {
                expanded.toggle()
            } label: {
                Image(systemName: expanded ? "chevron.up" : "info.circle")
            }
            .buttonStyle(.plain)
            .help(expanded ? "Hide details" : "Show details")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .font(.caption)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var notifyButton: some View {
        if hasRule(action: .notify) {
            Button {
                removeRule(action: .notify)
            } label: {
                Label("Notifying", systemImage: "checkmark.circle.fill")
            }
            .tint(.blue)
            .help("Click to stop notifying for this app")
        } else {
            Button("Notify") {
                addRule(.notify)
            }
            .help("Add a rule: send a notification whenever this app starts blocking sleep.")
        }
    }

    @ViewBuilder
    private var sleepWhenIdleButton: some View {
        if hasRule(action: .forceSleep) {
            Button {
                removeRule(action: .forceSleep)
            } label: {
                Label("Sleeping when idle", systemImage: "checkmark.circle.fill")
            }
            .tint(.blue)
            .help("Click to remove the auto-sleep rule")
        } else {
            Button("Sleep When Idle") {
                addRule(.forceSleep)
            }
            .help("Add a rule: force sleep when this app blocks sleep AND you've been idle past your sleep timeout.")
        }
    }

    private var confirmBar: some View {
        HStack(spacing: 6) {
            Text(confirmMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Button("Cancel") { confirmingQuit = false }
            Button("Quit") {
                Actions.quit(group.representative)
                confirmingQuit = false
            }
            .tint(.red)
            Button("Quit & Remember") {
                Actions.quit(group.representative)
                addRule(.quit)
                confirmingQuit = false
            }
            .tint(.red)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .font(.caption)
        .padding(.top, 2)
    }

    private var confirmMessage: String {
        if group.count > 1 {
            return "Quit \(group.displayName)? (\(group.count) assertions)"
        }
        return "Quit \(group.displayName)?"
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AssertionInfo.summary(for: group.primaryAssertionType))
                .font(.caption)
            detailRow("Process", "\(group.displayName) (PID \(group.pid))")
            if let b = group.bundleID { detailRow("Bundle ID", b) }
            if let p = group.executablePath { detailRow("Path", p) }
            detailRow("Held for", formatDurationLong(group.durationOldest))

            if group.breakdown.count > 1 {
                Divider().padding(.vertical, 2)
                Text("Assertions held (\(group.count))")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                ForEach(group.breakdown, id: \.self) { b in
                    HStack(alignment: .top, spacing: 8) {
                        Text("×\(b.count)")
                            .font(.caption2.monospacedDigit().bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(b.type).font(.caption2.monospaced())
                            Text(b.name).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                }
            } else {
                detailRow("Assertion", group.representative.name)
                detailRow("Type", group.representative.assertionType)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(6)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.caption2.monospaced())
                .textSelection(.enabled)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
    }

    private func hasRule(action: RuleAction) -> Bool {
        ruleStore.rules.contains {
            $0.matchKey == Rule.keyFor(group.representative) && $0.action == action
        }
    }

    private func removeRule(action: RuleAction) {
        let key = Rule.keyFor(group.representative)
        for r in ruleStore.rules where r.matchKey == key && r.action == action {
            ruleStore.remove(r.id)
        }
    }

    private func addRule(_ action: RuleAction) {
        let rule = Rule(
            matchKey: Rule.keyFor(group.representative),
            displayName: group.displayName,
            assertionNameGlob: nil,
            action: action,
            enabled: true
        )
        ruleStore.add(rule)
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600, m = (s / 60) % 60, r = s % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(r)s" }
        return "\(r)s"
    }

    private func formatDurationLong(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600, m = (s / 60) % 60, r = s % 60
        if h > 0 { return "\(h)h \(m)m \(r)s" }
        if m > 0 { return "\(m)m \(r)s" }
        return "\(r)s"
    }
}
