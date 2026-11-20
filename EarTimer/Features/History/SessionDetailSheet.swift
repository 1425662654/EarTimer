import SwiftUI
import SwiftData

/// 记录详情：编辑起止时间、加备注、删除。
struct SessionDetailSheet: View {
    let record: SessionRecord
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageStore.self) private var lang

    @State private var start: Date
    @State private var end: Date
    @State private var note: String
    @State private var confirmDelete = false

    init(record: SessionRecord) {
        self.record = record
        _start = State(initialValue: record.startedAt)
        _end = State(initialValue: record.endedAt ?? .now)
        _note = State(initialValue: record.note ?? "")
    }

    private var language: AppLanguage { lang.language }
    private func t(_ key: L10n.Key) -> String { L10n.t(key, language) }

    var body: some View {
        NavigationStack {
            Form {
                Section(t(.detailDuration)) {
                    LabeledContent(t(.detailDuration)) {
                        Text(DurationText.clock(max(0, end.timeIntervalSince(start))))
                            .font(Theme.Font.monoMedium)
                    }
                    DatePicker(t(.detailStart), selection: $start, in: ...end, displayedComponents: [.date, .hourAndMinute])
                    DatePicker(t(.detailEnd), selection: $end, in: start..., displayedComponents: [.date, .hourAndMinute])
                }

                Section(t(.detailSourceSection)) {
                    LabeledContent(t(.detailHowRecorded), value: record.source.title(language))
                    LabeledContent(t(.detailChannel), value: record.channel.title(language))
                    if record.isEstimated {
                        Label(t(.detailEstimatedNote), systemImage: "exclamationmark.triangle")
                            .foregroundStyle(Theme.Palette.amber)
                            .font(Theme.Font.caption)
                    }
                    if record.hadCall {
                        Label(t(.detailHadCallNote), systemImage: "phone")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Palette.indigo)
                    }
                }

                Section(t(.detailNoteSection)) {
                    TextField(t(.detailNotePlaceholder), text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button(t(.detailDelete), role: .destructive) {
                        confirmDelete = true
                    }
                }
            }
            .navigationTitle(record.deviceName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t(.save)) {
                        record.startedAt = start
                        record.endedAt = record.isOpen ? nil : end
                        record.note = note.isEmpty ? nil : note
                        // 用户手动改过的记录不再标记为推算
                        record.isEstimated = false
                        record.source = .manual
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                t(.detailDeleteConfirmTitle),
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button(t(.delete), role: .destructive) {
                    context.delete(record)
                    try? context.save()
                    dismiss()
                }
            } message: {
                Text(t(.detailDeleteConfirmBody))
            }
        }
        .presentationDetents([.large])
    }
}
