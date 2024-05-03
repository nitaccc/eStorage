import SwiftUI
import Vision
import VisionKit

struct CameraView: View {
    @State private var isShowingCamera = false
    @State private var images: [UIImage] = []
    @State private var recognizedText = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(images.indices, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }

            Button("Take Photo") {
                self.isShowingCamera = true
            }
            .padding()
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(images: self.$images, recognizedText: self.$recognizedText)
            }

            Text(recognizedText)
                .padding()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Binding var recognizedText: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> VNDocumentCameraViewController {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = context.coordinator
        return documentCameraViewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: UIViewControllerRepresentableContext<ImagePicker>) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
            var parent: ImagePicker

            init(_ parent: ImagePicker) {
                self.parent = parent
            }

            func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
                for pageIndex in 0..<scan.pageCount {
                    let image = scan.imageOfPage(at: pageIndex)
                    parent.images.append(image)
                    recognizeText(from: image)
                }
            }

        func recognizeText(from image: UIImage) {
            guard let cgImage = image.cgImage else { return }

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    print("Error: \(error)")
                } else if let observations = request.results as? [VNRecognizedTextObservation] {
                    let recognizedString = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    DispatchQueue.main.async {
                        self.parent.recognizedText += recognizedString
                    }
                }
            }

            try? requestHandler.perform([request])
        }
    }
}
