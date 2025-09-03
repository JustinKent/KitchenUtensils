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

    @State private var isPresentingAddUtensil = false

    var body: some View {
        NavigationSplitView {
            UtensilListView()
                .navigationBarTitle("Kitchen Utensils")
                .toolbar {
                    ToolbarItem {
                        Button(action: { isPresentingAddUtensil = true }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $isPresentingAddUtensil) {
            AddUtensilView()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Utensil(
                name: "New Utensil",
                creationDate: Date()
            )
            modelContext.insert(newItem)
        }
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Utensil.self, inMemory: true)
}
