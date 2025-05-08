import SwiftUI
import UIKit // For UIImagePickerController and related delegates

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    // ADD: sourceType property to specify camera or photo library
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) private var presentationMode

    // No explicit init needed as Swift will generate a memberwise initializer

    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("ImagePicker DEBUG: makeUIViewController called. Requested sourceType: \(self.sourceType)")
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        // Use the provided sourceType, but fallback if it's not available
        if UIImagePickerController.isSourceTypeAvailable(self.sourceType) {
            picker.sourceType = self.sourceType
            print("ImagePicker: Successfully set sourceType to \(self.sourceType)")
        } else {
            // If the requested source (e.g., .camera on a device without one) isn't available,
            // fall back to the photo library.
            print("ImagePicker: Requested sourceType \(self.sourceType) is not available. Falling back to .photoLibrary.")
            picker.sourceType = .photoLibrary
        }
        
        // Note: On the simulator, if sourceType is .camera,
        // UIImagePickerController might show a test pattern, a black screen, or its own photo library fallback.
        // This behavior is controlled by the system's UIImagePickerController.

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        print("ImagePicker DEBUG: makeCoordinator called.")
        return Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
