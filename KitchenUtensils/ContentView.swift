//
//  ContentView.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/2/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
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
}

#Preview {
    ContentView()
        .modelContainer(for: Utensil.self, inMemory: true)
}
