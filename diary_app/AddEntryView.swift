//
//  AddEntryView.swift
//  diary_app
//
//  Created by Anton on 01/11/2025.
//

import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DiaryViewModel
    
    @State private var title = ""
    @State private var feeling = ""
    @State private var content = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Enter title", text: $title)
                }

                let emojiOptions = ["😀", "😢", "😡", "😱", "🥰", "😴", "🤔", "😇", "😎", "😭", "🥳", "😤"]
                Section(header: Text("Feeling")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Text(emoji)
                                .font(.largeTitle)
                                .padding(6)
                                .background(feeling == emoji ? Color.blue.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture {
                                    feeling = emoji
                                }
                        }
                    }
                }

                Section(header: Text("Content")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addEntry(title: title, feeling: feeling, content: content)
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
