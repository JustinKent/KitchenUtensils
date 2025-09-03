//
//  UtensilListCellView.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/3/25.
//

import SwiftUI

struct UtensilListCellView: View {
    let utensil: Utensil
    
    var body: some View {
        HStack {
            UtensilCellThumbnailView(utensil: utensil)
            VStack(alignment: .leading) {
                Text(utensil.name)
                    .font(.headline)
                Text("\(utensil.creationDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct UtensilCellThumbnailView: View {
    @Environment(\.imageRepository) private var imageRepository
    let utensil: Utensil
    
    @State private var image: UIImage?
    
    var body: some View {
        VStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
                    .accessibilityIdentifier("\(utensil.name) Image")
            } else {
                placeholder
            }
        }
        .task(id: utensil.id) {
            image = await imageRepository.thumbnail(for: utensil.id.uuidString)
        }
    }
    
    private var placeholder: some View {
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

#Preview {
    List {
        UtensilListCellView(utensil: .sampleSpatula)
        UtensilListCellView(utensil: .sampleWhisk)
    }
}

fileprivate extension Utensil {
    static var sampleSpatula: Utensil {
        Utensil(
            id: UUID(),
            name: "Spatula",
            creationDate: Date(timeIntervalSinceReferenceDate: 778_543_810)
        )
    }
    
    static var sampleWhisk: Utensil {
        Utensil(
            id: UUID(),
            name: "Whisk",
            creationDate: Date(timeIntervalSinceReferenceDate: 778_543_566)
        )
    }
}
