//
//  KitchenUtensilsApp.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/2/25.
//

import SwiftUI
import SwiftData

@main
struct KitchenUtensilsApp: App {
    private let imageRepository = ImageRepository()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Utensil.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.imageRepository, imageRepository)
        }
        .modelContainer(sharedModelContainer)
    }
}
