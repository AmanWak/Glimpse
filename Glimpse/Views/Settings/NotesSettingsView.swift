//
//  NotesSettingsView.swift
//  Glimpse
//
//  Notes tab: toggle and editor for the reminders shown during breaks.
//

import SwiftUI

struct NotesSettingsView: View {
    @Bindable var appState: AppState
    @State private var newNote: String = ""

    var body: some View {
        Form {
            Section {
                Toggle("Show notes during breaks", isOn: $appState.breakNotesEnabled)

                Text("Short reminders shown on the right side of the overlay during breaks.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if appState.breakNotesEnabled {
                Section("Your notes") {
                    ForEach(Array(appState.breakNotes.enumerated()), id: \.offset) { index, note in
                        HStack {
                            Text(note)
                            Spacer()
                            Button {
                                var notes = appState.breakNotes
                                notes.remove(at: index)
                                appState.breakNotes = notes
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        TextField("Add a note...", text: $newNote)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addNote()
                            }
                        Button {
                            addNote()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        .disabled(newNote.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    Button("Reset to Defaults") {
                        appState.breakNotes = Constants.defaultBreakNotes
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func addNote() {
        let trimmed = newNote.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var notes = appState.breakNotes
        notes.append(trimmed)
        appState.breakNotes = notes
        newNote = ""
    }
}

#Preview {
    NotesSettingsView(appState: AppState())
}
