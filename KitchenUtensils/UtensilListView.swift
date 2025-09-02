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
    @Environment(\.imageRepository) private var imageRepository
    @Query(sort: \Utensil.creationDate, order: .reverse) private var utensils: [Utensil]

    var body: some View {
        Group {
            if utensils.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(utensils) { utensil in
                        NavigationLink {
                            UtensilDetailView(utensil: utensil)
                        } label: {
                            UtensilCellView(utensil: utensil)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            ContentUnavailableView(
                "No Utensils",
                systemImage: "fork.knife",
                description: Text("Add a utensil to get started.")
            )
        }
        .padding()
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(utensils[index])
            }
        }
    }
}

private struct UtensilCellView: View {
    let utensil: Utensil
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(utensil.name)
                .font(.headline)
            Text("\(utensil.creationDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        
    }
}

private struct UtensilDetailView: View {
    let utensil: Utensil
    
    var body: some View {
        Text(utensil.name)
            .font(.headline)
        Text("Created: \(utensil.creationDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
        Text(utensil.id.uuidString)
    }
}

// MARK: - Previews

private extension Utensil {
    static var sampleSpatula: Utensil {
        Utensil(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
            name: "Spatula",
            creationDate: Date(timeIntervalSinceReferenceDate: 778_543_810)
        )
    }
    
    static var sampleWhisk: Utensil {
        Utensil(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555") ?? UUID(),
            name: "Whisk",
            creationDate: Date(timeIntervalSinceReferenceDate: 778_543_566)
        )
    }
}

#Preview("UtensilCellView - Spatula") {
    List {
        UtensilCellView(utensil: .sampleSpatula)
        UtensilCellView(utensil: .sampleWhisk)
    }
}

#Preview("UtensilDetailView - Spatula") {
    NavigationStack {
        UtensilDetailView(utensil: .sampleSpatula)
            .navigationTitle("Details")
    }
}

#Preview("UtensilListView (empty)") {
    NavigationStack {
        UtensilListView()
            .navigationTitle("Kitchen Utensils")
    }
    .modelContainer(for: Utensil.self, inMemory: true)
}
