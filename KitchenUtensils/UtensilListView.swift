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
                let utensil = utensils[index]
                modelContext.delete(utensil)
                Task {
                    await imageRepository.delete(utensil.id.uuidString)
                }
            }
        }
    }
}

private struct UtensilCellView: View {
    let utensil: Utensil
    @Environment(\.imageRepository) private var imageRepository
    
    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            VStack(alignment: .leading) {
                Text(utensil.name)
                    .font(.headline)
                Text("\(utensil.creationDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var thumbnailView: some View {
        Group {
            if let uiImage = imageRepository.thumbnail(for: utensil.id.uuidString) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
                    .accessibilityIdentifier("\(utensil.name) Image")
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 60, height: 60)
                .accessibilityIdentifier("Utensil Image Placeholder")
            }
        }
    }
}

private struct UtensilDetailView: View {
    let utensil: Utensil
    @Environment(\.imageRepository) private var imageRepository

    var body: some View {
        ScrollView {
            imageView
            Text("Created: \(utensil.creationDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
            Text(utensil.id.uuidString)
        }
        .navigationTitle(utensil.name)
    }
    
    private var imageView: some View {
        Group {
            if let uiImage = imageRepository.original(for: utensil.id.uuidString) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .accessibilityIdentifier("\(utensil.name) Image")
            } else {
                EmptyView()
            }
        }
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
