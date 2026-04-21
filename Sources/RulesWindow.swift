import SwiftUI

struct RulesWindow: View {
    @EnvironmentObject var ruleStore: RuleStore
    @State private var selection: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Automatic actions").font(.title2).bold()
                Spacer()
            }

            Text("When one of these apps starts preventing sleep, the chosen action runs automatically.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if ruleStore.rules.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No rules yet").font(.headline)
                    Text("From the menu bar, click 'Quit & always do this' on any blocker to add a rule.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(ruleStore.rules, selection: $selection) {
                    TableColumn("App") { rule in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.displayName)
                            Text(rule.matchKey)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    TableColumn("Action") { rule in
                        Picker("", selection: bindAction(for: rule)) {
                            ForEach(RuleAction.allCases, id: \.self) { a in
                                Text(a.label).tag(a)
                            }
                        }
                        .labelsHidden()
                    }
                    .width(120)
                    TableColumn("Wait until idle") { rule in
                        IdleThresholdField(rule: rule)
                            .environmentObject(ruleStore)
                    }
                    .width(140)
                    TableColumn("Enabled") { rule in
                        Toggle("", isOn: bindEnabled(for: rule))
                            .labelsHidden()
                    }
                    .width(60)
                }

                HStack {
                    Spacer()
                    Button("Delete Rule") {
                        if let id = selection { ruleStore.remove(id) }
                    }
                    .disabled(selection == nil)
                }
            }
        }
        .padding(20)
    }

    private func bindAction(for rule: Rule) -> Binding<RuleAction> {
        Binding(
            get: { rule.action },
            set: { newValue in
                var r = rule
                r.action = newValue
                ruleStore.update(r)
            }
        )
    }

    private func bindEnabled(for rule: Rule) -> Binding<Bool> {
        Binding(
            get: { rule.enabled },
            set: { newValue in
                var r = rule
                r.enabled = newValue
                ruleStore.update(r)
            }
        )
    }
}

struct IdleThresholdField: View {
    let rule: Rule
    @EnvironmentObject var ruleStore: RuleStore
    @State private var text: String = ""

    var body: some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .onAppear { text = initialText }
                .onChange(of: text) { _ in commit() }
                .onSubmit { commit() }
            Text("min")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .help(helpText)
    }

    private var placeholder: String {
        switch rule.action {
        case .forceSleep, .notify: return "auto"
        case .quit: return "0"
        }
    }

    private var initialText: String {
        guard let s = rule.idleThresholdSeconds else { return "" }
        let minutes = Double(s) / 60.0
        if minutes.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(minutes))
        }
        return String(format: "%g", minutes)
    }

    private var helpText: String {
        switch rule.action {
        case .notify: return "Wait until idle this many minutes before notifying. Decimals allowed (0.1 = 6s). Leave blank for macOS display-sleep default."
        case .quit: return "Wait until idle this many minutes before quitting. Decimals allowed (0.1 = 6s). 0 = immediate."
        case .forceSleep: return "Wait until idle this many minutes before forcing sleep. Decimals allowed (0.1 = 6s). Leave blank for macOS display-sleep default."
        }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        var r = rule
        if trimmed.isEmpty {
            r.idleThresholdSeconds = nil
        } else if let minutes = Double(trimmed), minutes >= 0 {
            r.idleThresholdSeconds = Int(round(minutes * 60))
        } else {
            return
        }
        ruleStore.update(r)
    }
}
