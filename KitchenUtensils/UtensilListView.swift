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
                            UtensilListCellView(utensil: utensil)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView("No Utensils",
                               systemImage: "fork.knife",
                               description: Text("Add a utensil to get started."))
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

#Preview {
    NavigationStack {
        UtensilListView()
            .navigationTitle("Kitchen Utensils")
    }
    .modelContainer(for: Utensil.self, inMemory: true)
}
