//
//  AddUtensilView.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/2/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import SwiftData

struct AddUtensilView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.imageRepository) private var imageRepository
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddUtensilViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)

                    if let message = viewModel.nameValidationMessage, !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("nameValidationMessage")
                    }
                }

                Section("Photo") {
                    let hasPreview = (viewModel.pickedUIImage != nil)
                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        PhotoPickerLabel(hasPreview: hasPreview)
                    }

                    if let previewImage = viewModel.pickedUIImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .cornerRadius(8)
                                .accessibilityIdentifier("Image Preview")
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Add Utensil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.save(
                                modelContext: modelContext,
                                imageRepository: imageRepository,
                                onSuccess: { dismiss() }
                            )
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!viewModel.enableSave)
                }
            }
            .alert("Could Not Save", isPresented: $viewModel.showingSaveError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(viewModel.saveErrorMessage ?? "An unknown error occurred.")
            })
        }
    }
}

private struct PhotoPickerLabel: View {
    let hasPreview: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "photo.on.rectangle")
            Text(hasPreview ? "Choose Different Photo" : "Choose Photo")
        }
    }
}

#Preview {
    AddUtensilView()
}

