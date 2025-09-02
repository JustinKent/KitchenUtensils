//
//  ContentView.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/2/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Utensil]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text(item.name)
                            .font(.headline)
                        Text("Created: \(item.creationDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        Text("File extension: .\(item.fileExtension)")
                        Text(item.id.uuidString)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            Text("\(item.creationDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Utensil(
                name: "New Utensil",
                fileExtension: "heic",
                creationDate: Date()
            )
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Utensil.self, inMemory: true)
}
