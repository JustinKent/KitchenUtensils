//
//  UtensilListView.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/2/25.
//

import SwiftData
import SwiftUI

struct UtensilListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Utensil.creationDate, order: .reverse) private var items: [Utensil]

    var body: some View {
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
    UtensilListView()
}
