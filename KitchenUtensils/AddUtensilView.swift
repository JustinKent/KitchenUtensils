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

    // Form state
    @State private var name: String = ""
    @State private var nameValidationMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickedImageData: Data?
    @State private var pickedUIImage: UIImage?

    // Derivatives
    private let maxNameLength = 100

    // Save state
    @State private var isSaving = false
    @State private var saveErrorMessage: String?
    @State private var showingSaveError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _, newValue in
                            validateName(newValue)
                        }
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)

                    if let message = nameValidationMessage, !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("nameValidationMessage")
                    }
                }

                Section("Photo") {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(pickedUIImage == nil ? "Choose Photo" : "Choose Different Photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task { await loadPickedPhoto(from: newItem) }
                    }

                    if let preview = pickedUIImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Image(uiImage: preview)
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
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .alert("Could Not Save", isPresented: $showingSaveError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(saveErrorMessage ?? "An unknown error occurred.")
            })
        }
    }

    // MARK: - Validation

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNameValid: Bool {
        nameValidationMessage == nil && !trimmedName.isEmpty
    }

    private var hasPickedImage: Bool {
        pickedImageData != nil && pickedUIImage != nil
    }

    private var canSave: Bool {
        isNameValid && hasPickedImage
    }

    private func validateName(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            nameValidationMessage = "Please enter a name."
            return
        }

        if trimmed.count > maxNameLength {
            nameValidationMessage = "Name must be \(maxNameLength) characters or fewer."
            return
        }

        nameValidationMessage = nil
    }

    // MARK: - Photo loading

    @MainActor
    private func loadPickedPhoto(from item: PhotosPickerItem?) async {
        pickedImageData = nil
        pickedUIImage = nil

        guard let item else { return }

        // Prefer original image data if available
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                pickedImageData = data
                pickedUIImage = UIImage(data: data)
                return
            }
        } catch {
            // Fall through to next attempt
        }
    }

    // MARK: - Save

    @MainActor
    private func save() async {
        guard canSave, let imageData = pickedImageData else { return }
        isSaving = true
        defer { isSaving = false }

        // Decide file extension: attempt to infer from data (or PhotosPicker item), else default to jpg
        let ext = inferredFileExtension(from: imageData) ?? "jpg"

        // Create a new utensil first to get its UUID for image naming
        let utensil = Utensil(
            id: UUID(),
            name: trimmedName,
            creationDate: Date()
        )

        do {
            // Write the picked image data to a temporary file, then hand off to repository
            let tempURL = try writeToTemporaryFile(data: imageData, withExtension: ext)

            // Store original + thumbnail using utensil.id as the key
            try await imageRepository.add(image: tempURL, named: utensil.id.uuidString)

            // Persist the model
            modelContext.insert(utensil)

            // Cleanup temp file
            try? FileManager.default.removeItem(at: tempURL)

            // Dismiss on success
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
    }

    private func writeToTemporaryFile(data: Data, withExtension ext: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "picked-\(UUID().uuidString).\(ext)"
        let url = tempDir.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func inferredFileExtension(from data: Data) -> String? {
        // Infer from file signatures (very simple)
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" } // JPEG
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" } // PNG
        if data.starts(with: [0x52, 0x49, 0x46, 0x46]) { return "heic" } // HEIC/HEIF may vary; this is not precise
        // Could expand with UTType detection if needed
        return nil
    }
}

#Preview {
    AddUtensilView()
}
