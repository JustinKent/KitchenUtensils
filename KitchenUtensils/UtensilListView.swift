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
    @Query(sort: \Utensil.creationDate, order: .reverse) private var utensils: [Utensil]

    var body: some View {
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
        Text("File extension: .\(utensil.fileExtension)")
        Text(utensil.id.uuidString)
    }
}

#Preview {
    UtensilListView()
}
