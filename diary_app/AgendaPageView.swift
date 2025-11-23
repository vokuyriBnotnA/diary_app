//
//  AgendaPageView.swift
//  diary_app
//
//  Created by Anton on 03/11/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AgendaPageView: View {
    @ObservedObject var viewModel: DiaryViewModel
    @State private var selectedDate = Date()
    @State private var selectedEntry: DiaryEntry?
    
    // Записи, отфильтрованные по дате
    private var filteredEntries: [DiaryEntry] {
        viewModel.entries.filter { entry in
            Calendar.current.isDate(entry.createdAt, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Календарь
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Divider()
                
                // MARK: - Список записей за выбранную дату
                if filteredEntries.isEmpty {
                    Text("No entries for this date.")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: EntryDetailView(entry: entry, viewModel: viewModel)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title)
                                        .font(.headline)
                                    Text(entry.feeling)
                                        .font(.largeTitle)
                                    Text(entry.createdAt, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            deleteEntries(at: offsets)
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Agenda")
            .onAppear {
                viewModel.loadEntries()
            }
        }
    }
    
    // MARK: - Удаление записи и обновление списка
    private func deleteEntries(at offsets: IndexSet) {
        guard let user = Auth.auth().currentUser else { return }
        
        offsets.forEach { index in
            let entry = filteredEntries[index]
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
