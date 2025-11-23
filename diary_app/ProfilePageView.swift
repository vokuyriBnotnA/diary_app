//
//  ProfilePageView.swift
//  diary_app
//
//  Created by Anton on 03/11/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfilePageView: View {
    @ObservedObject var viewModel = DiaryViewModel()
    @State private var userName: String = ""
    @Environment(\.dismiss) var dismiss
    @State private var showingAddEntry = false
    @State private var selectedEntry: DiaryEntry?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - User Info
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome,")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(userName.isEmpty ? "User" : userName)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Button(action: logout) {
                            Text("Log out")
                                .foregroundColor(.red)
                        }
                    }

                    Divider()

                    // MARK: - Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total entries: \(viewModel.entries.count)")
                            .font(.headline)
                        feelingStatsView
                    }

                    Divider()

                    // MARK: - Recent Entries
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last 2 Entries")
                            .font(.headline)
                        if viewModel.entries.isEmpty {
                            Text("No entries yet.")
                                .foregroundColor(.gray)
                        } else {
                            List {
                                ForEach(viewModel.entries.prefix(2)) { entry in
                                    Button {
                                        selectedEntry = entry
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.title)
                                                .font(.headline)
                                            Text(entry.feeling)
                                                .font(.largeTitle)
                                            Text(entry.createdAt, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                .onDelete(perform: deleteEntry)
                            }
                            .frame(height: 200)
                            .listStyle(.plain)
                        }
                    }

                    Divider()

                    // MARK: - Add New Entry Button
                    Button(action: { showingAddEntry.toggle() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Entry")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(viewModel: viewModel)
            }
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry, viewModel: viewModel)
            }
            .onAppear {
                loadUser()
                viewModel.loadEntries()
            }
        }
    }

    // MARK: - Feeling Stats
    private var feelingStatsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            let stats = viewModel.calculateFeelingStats()
            if stats.isEmpty {
                Text("No feelings recorded yet.")
                    .foregroundColor(.gray)
            } else {
                ForEach(stats.sorted(by: { $0.value > $1.value }), id: \.key) { feeling, percent in
                    HStack {
                        Text(feeling)
                        Spacer()
                        Text(String(format: "%.1f%%", percent))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // MARK: - Logout
    private func logout() {
        do {
            try Auth.auth().signOut()
            dismiss()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // MARK: - Load user info
    private func loadUser() {
        if let user = Auth.auth().currentUser {
            self.userName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User"
        }
    }

    private func deleteEntry(at offsets: IndexSet) {
        guard let user = Auth.auth().currentUser else { return }
        offsets.forEach { index in
            let entry = viewModel.entries.prefix(2)[index]
            viewModel.db.collection("users")
                .document(user.uid)
                .collection("entries")
                .document(entry.id)
                .delete { error in
                    if let error = error {
                        print("Error deleting entry: \(error.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            if let i = viewModel.entries.firstIndex(where: { $0.id == entry.id }) {
                                viewModel.entries.remove(at: i)
                            }
                        }
                    }
                }
        }
    }
}
