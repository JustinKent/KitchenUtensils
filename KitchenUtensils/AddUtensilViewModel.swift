//
//  AddUtensilViewModel.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/3/25.
//

import PhotosUI
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AddUtensilViewModel {
    // Form state
    var name: String = "" {
        didSet {
            Task {
                if !name.isEmpty {
                    validateName(name)
                }
            }
        }
    }
    var nameValidationMessage: String?
    var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            Task {
                await loadPickedPhoto(from: selectedPhotoItem)
            }
        }
    }
    var pickedImageData: Data?
    var pickedUIImage: UIImage?
    
    // Save state
    var isSaving = false
    var saveErrorMessage: String?
    var showingSaveError = false
    
    private let maxNameLength = 100
    
    // Derived
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isNameValid: Bool {
        nameValidationMessage == nil && !trimmedName.isEmpty
    }
    
    var hasPickedImage: Bool {
        pickedImageData != nil && pickedUIImage != nil
    }
    
    var canSave: Bool {
        isNameValid && hasPickedImage
    }
    
    var enableSave: Bool {
        canSave && !isSaving
    }
    
    // MARK: - Validation
    
    func validateName(_ newValue: String) {
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
    func loadPickedPhoto(from item: PhotosPickerItem?) async {
        pickedImageData = nil
        pickedUIImage = nil
        
        guard let item else { return }
        
        if let data = try? await item.loadTransferable(type: Data.self) {
            pickedImageData = data
            pickedUIImage = UIImage(data: data)
            return
        }
    }
    
    // MARK: - Save
    
    @MainActor
    func save(modelContext: ModelContext,
              imageRepository: ImageRepository,
              onSuccess: @escaping () -> Void) async {
        guard canSave, let imageData = pickedImageData else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        let ext = inferredFileExtension(from: imageData) ?? "jpg"
        
        let utensil = Utensil(
            id: UUID(),
            name: trimmedName,
            creationDate: Date()
        )
        
        do {
            let tempURL = try writeToTemporaryFile(data: imageData, withExtension: ext)
            
            try await imageRepository.add(image: tempURL, named: utensil.id.uuidString)
            
            modelContext.insert(utensil)
            
            try? FileManager.default.removeItem(at: tempURL)
            
            onSuccess()
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
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" } // JPEG
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" } // PNG
        if data.starts(with: [0x52, 0x49, 0x46, 0x46]) { return "heic" } // Rough HEIC/HEIF hint
        return nil
    }
}
