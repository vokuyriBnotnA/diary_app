//
//  EntryDetailView.swift
//  diary_app
//
//  Created by Anton on 01/11/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EntryDetailView: View {
    let entry: DiaryEntry
    @ObservedObject var viewModel: DiaryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(entry.feeling)
                    .font(.largeTitle)

                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider()

                Text(entry.content)
                    .font(.body)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete this entry?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func deleteEntry() {
        guard let user = Auth.auth().currentUser else { return }

        viewModel.db.collection("users")
            .document(user.uid)
            .collection("entries")
            .document(entry.id)
            .delete { error in
                if let error = error {
                    print("Error deleting entry: \(error.localizedDescription)")
                } else {
                    print("Entry successfully deleted from detail view.")
                    DispatchQueue.main.async {
                        if let index = viewModel.entries.firstIndex(where: { $0.id == entry.id }) {
                            viewModel.entries.remove(at: index)
                        }
                        dismiss()
                    }
                }
            }
    }
}
