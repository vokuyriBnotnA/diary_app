//
//  DiaryView.swift
//  diary_app
//
//  Created by Anton on 30/10/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct DiaryView: View {
    @StateObject var viewModel = DiaryViewModel()
    @State private var showingAddEntry = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.entries) { entry in
                    NavigationLink(destination: EntryDetailView(entry: entry, viewModel: viewModel)) {
                        VStack(alignment: .leading) {
                            Text(entry.title).font(.headline)
                            Text(entry.feeling).italic()
                            Text(entry.content).font(.body).lineLimit(3)
                            Text(entry.createdAt, style: .date).font(.caption)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .onDelete(perform: viewModel.deleteEntry)
            }
            .navigationTitle("Diary")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEntry.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.loadEntries()
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - MainView with TabView
struct MainView: View {
    @State private var selectedTab = 0
    @StateObject var viewModel = DiaryViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
//            DiaryView(viewModel: viewModel)
//                .tabItem {
//                    Label("Diary", systemImage: "book")
//                }
//                .tag(0)
            
            ProfilePageView(viewModel: viewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(1)
            AgendaPageView(viewModel: viewModel)
                .tabItem {
                    Label("Calendar", systemImage: "calendar.circle")
                }
                .tag(2)
        }
    }
}

// MARK: - DiaryEntry model
struct DiaryEntry: Identifiable {
    let id: String
    let date: Date
    let title: String
    let feeling: String
    let content: String
    let createdAt: Date
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        guard let title = data["title"] as? String,
              let feeling = data["feeling"] as? String,
              let content = data["content"] as? String else {
            return nil
        }
        
        // createdAt and date may be stored as Firestore Timestamp
        if let createdTs = data["createdAt"] as? Timestamp {
            self.createdAt = createdTs.dateValue()
        } else if let createdDate = data["createdAt"] as? Date {
            self.createdAt = createdDate
        } else if let dateTs = data["date"] as? Timestamp {
            self.createdAt = dateTs.dateValue()
        } else {
            self.createdAt = Date()
        }
        
        if let dateTs = data["date"] as? Timestamp {
            self.date = dateTs.dateValue()
        } else if let dateVal = data["date"] as? Date {
            self.date = dateVal
        } else {
            self.date = self.createdAt
        }
        
        self.id = document.documentID
        self.title = title
        self.feeling = feeling
        self.content = content
    }
}

// MARK: - ViewModel
final class DiaryViewModel: ObservableObject {
    @Published var entries: [DiaryEntry] = []
    
    let db = Firestore.firestore()
    
    func loadEntries() {
        
        guard let user = Auth.auth().currentUser else {
            // no logged in user — clear entries
            DispatchQueue.main.async {
                self.entries = []
            }
            return
        }
        
        if let user = Auth.auth().currentUser {
            print("Current user UID:", user.uid)
        } else {
            print("⚠️ No user logged in")
        }
        
        db.collection("users")
            .document(user.uid)
            .collection("entries")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching entries: \(error)")
                    return
                }
                
                let docs = snapshot?.documents ?? []
                let mapped = docs.compactMap { DiaryEntry(document: $0) }
                
                DispatchQueue.main.async {
                    self.entries = mapped
                }
            }
    }
    
    func addEntry(title: String, feeling: String, content: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        let entryData: [String: Any] = [
            "title": title,
            "feeling": feeling,
            "content": content,
            "date": Timestamp(date: Date()),
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("users")
            .document(user.uid)
            .collection("entries")
            .addDocument(data: entryData) { error in
                if let error = error {
                    print("Error adding entry: \(error.localizedDescription)")
                } else {
                    print("Entry successfully added.")
                    self.loadEntries() // обновляем список после добавления
                }
            }
    }
    
    func deleteEntry(at offsets: IndexSet) {
        guard let user = Auth.auth().currentUser else { return }
        
        offsets.forEach { index in
            let entry = entries[index]
            db.collection("users")
                .document(user.uid)
                .collection("entries")
                .document(entry.id)
                .delete { error in
                    if let error = error {
                        print("Error deleting entry: \(error.localizedDescription)")
                    } else {
                        print("Entry successfully deleted.")
                        DispatchQueue.main.async {
                            self.entries.remove(at: index)
                        }
                    }
                }
        }
    }
    
    func calculateFeelingStats() -> [String: Double] {
        guard !entries.isEmpty else { return [:] }
        
        let total = Double(entries.count)
        let counts = Dictionary(grouping: entries, by: { $0.feeling })
            .mapValues { Double($0.count) }
        
        var result: [String: Double] = [:]
        for (feeling, count) in counts {
            result[feeling] = (count / total) * 100
        }
        
        return result
    }
}
