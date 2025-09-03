//
//  UtensilDetailView.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/3/25.
//

import SwiftUI

struct UtensilDetailView: View {
    let utensil: Utensil
    
    var body: some View {
        ScrollView {
            UtensilDetailImageView(utensil: utensil)
            Text("Created: \(utensil.creationDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
            Text(utensil.id.uuidString)
        }
        .navigationTitle(utensil.name)
    }
}

private struct UtensilDetailImageView: View {
    @Environment(\.imageRepository) private var imageRepository
    let utensil: Utensil
    
    @State private var image: UIImage?
    
    var body: some View {
        VStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .accessibilityIdentifier("\(utensil.name) Image")
            } else {
                placeholder
            }
        }
        .task(id: utensil.id) {
            image = await imageRepository.original(for: utensil.id.uuidString)
        }
    }
    
    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.15)
            Image(systemName: "photo")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipped()
        .accessibilityIdentifier("Utensil Image Placeholder")
    }
}

#Preview {
    NavigationStack {
        UtensilDetailView(utensil: .sampleSpatula)
            .navigationTitle("Details")
    }
}

private extension Utensil {
    static var sampleSpatula: Utensil {
        Utensil(
            id: UUID(),
            name: "Spatula",
            creationDate: Date(timeIntervalSinceReferenceDate: 778_543_810)
        )
    }
}
