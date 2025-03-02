//
//  ContentView.swift
//  BrailleTranslator
//
//  Created by Yukiko Nii on 2025/03/01.
//

import SwiftUI
import UIKit
import Foundation
import AVFoundation
import CoreML
import Vision
import AVFoundation



struct ContentView: View {
    private var prim = Color(UIColor(light: .darkPrim, dark: .darkPrim))
    private var sec = Color(UIColor(light: .lightSec, dark: .lightSec))
    @State private var selectedTab = 1
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                BrailleView()
                    .tag(1)
                ObjectDetectionView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hides the default page indicator
            
            Spacer()
            
            HStack {
                Button(action: { self.selectedTab = 1 }) {
                    VStack {
                        Image(systemName: "hand.point.up.braille.fill")
                            .font(.system(size: 24))
                            .foregroundColor(self.selectedTab == 1 ? prim : sec)
                        Text("Braille")
                            .font(.footnote)
                            .foregroundColor(self.selectedTab == 1 ? prim : sec)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: { self.selectedTab = 2 }) {
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 24))
                            .foregroundColor(self.selectedTab == 2 ? prim : sec)
                        Text("Location")
                            .font(.footnote)
                            .foregroundColor(self.selectedTab == 2 ? prim : sec)
                    }
                }
                .frame(maxWidth: .infinity)
                
                
            }
            .padding()
            .background(Color.white)
            .border(Color.gray.opacity(0.3), width: 1)
            .clipShape(RoundedRectangle(cornerRadius: 20)) // Apply rounded corners
            .shadow(radius: 10) // Optional: Adds a subtle shadow for depth
            .padding() // Adds spacing from edges
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
// Convert UIImage to Base64 and analyze
    func processCapturedImage(_ image: UIImage) {
        print("Image captured. Converting to Base64...")

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let base64String = imageData.base64EncodedString()
            Task {
                await analyseImage(base64Image: base64String)
            }
        } else {
            print("Failed to convert image to Base64.")
        }
    }

    // Function to analyze captured image

    func analyseImage(base64Image: String) async {
        print("Image captured and sent to analysis function")
        
        let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: openAIURL)
        request.httpMethod = "POST"
        request.addValue("Bearer YOUR_OPENAI_API_KEY", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // let json: [String: Any] = [
        //     "model": "gpt-4-vision-preview",  // Correct model name
        //     "messages": [
        //         ["role": "system", "content": "You are a helpful assistant which guides visually impaired people navigate their surroundings."],
        //         [
        //             "role": "user",
        //             "content": [
        //                 ["type": "text", "text": "Analyze the image and describe the surroundings with guidance on safe movement directions."],
        //                 ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
        //             ]
        //         ]
        //     ],
        //     "max_tokens": 500
        // ]
        
        // do {
        //     let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        //     request.httpBody = jsonData
            
        //     let (data, _) = try await URLSession.shared.data(for: request)
            
            // if let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            // let choices = responseJSON["choices"] as? [[String: Any]],
            // let textResponse = choices.first?["message"] as? [String: Any],
            // let content = textResponse["content"] as? String {
                
            //     await MainActor.run {
            //         self.speak(text: content) // Ensure speak() is async-compatible
            //     }
            // }
        // } catch {
        //     print("Error analyzing image: \(error)")
        // }
    }

    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}


struct BrailleView: View {
    private var prim = Color(UIColor(light: .darkPrim, dark: .darkPrim))
    private var sec = Color(UIColor(light: .lightSec, dark: .lightSec))
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var image: UIImage?
    @State private var responseText: String = ""
    @State private var isLoading: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false

    
    var body: some View {
        VStack {
            HStack {
               
                Text("Braille Reader")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(prim)
            }
            
            Divider()
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
            } else {
                Text("No Image Selected")
                    .foregroundColor(sec)
            }
            
            HStack(spacing: 20) {
                Button("Take Photo") {
                    self.sourceType = .camera
                    self.showImagePicker = true
                }
                .padding()
                .background(prim)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 10)
                
                Button("Choose Photo") {
                    self.sourceType = .photoLibrary
                    self.showImagePicker = true
                }
                .padding()
                .background(prim)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .padding()
            
            if image != nil {
                Button("Send Image") {
                    if let image = image {
                        isLoading = true
                        readBraille(image:image)
                    }
                }
                .padding()
                .background(prim)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding()
            }
            
            // Display the response text
            if isLoading {
                ProgressView()
                    .padding()
            } else if !responseText.isEmpty {
                Text("\(responseText)")
                    .padding()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    
            }
            
            Button("Play Audio") {
                fetchAndPlayAudio(text: "\(responseText)", language: "en")
           }
           .padding()
           .background(prim)
           .foregroundColor(.white)
           .cornerRadius(15)
           .shadow(radius: 10)
           .padding()

        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: self.$image, isPresented: self.$showImagePicker, sourceType: self.sourceType)
        }
        .onChange(of: responseText) { oldValue, newValue in
                    // Auto-play audio when responseText becomes available
                    if !newValue.isEmpty {
                        fetchAndPlayAudio(text: newValue, language: "en")
                    }
        }
    }
    
    // Function to fetch and play audio
        func fetchAndPlayAudio(text: String, language: String) {
            guard let url = URL(string: "http://10.97.229.235:5001/text_to_audio") else {
                print("Invalid URL")
                return
            }

            let requestBody: [String: Any] = [
                "text": text,
                "lang": language
            ]

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            } catch {
                print("Error encoding request body: \(error)")
                return
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("No data received")
                    return
                }
                
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Parsed JSON Response:", json)
                        if let audioURLString = json["audio_url"] as? String,
                            let audioURL = URL(string: audioURLString) {
                            // Download and play the audio file
                            self.downloadAndPlayAudio(from: audioURL)
                        }
                        
                    } else {
                        print("Invalid JSON response")
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            task.resume()
        }
    
    func downloadAndPlayAudio(from url: URL) {
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                return
            }

            guard let localURL = localURL else {
                print("No local URL received")
                return
            }

            do {
                // Initialize the audio player with the downloaded file
                self.audioPlayer = try AVAudioPlayer(contentsOf: localURL)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                
            } catch {
                print("Error initializing audio player: \(error)")
            }
        }
        downloadTask.resume()
    }
    
    
    
    func readBraille(image: UIImage) {
            let url = URL(string: "http://10.97.229.235:5001/read_braille")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            let filename = "braille.jpg"
            let fieldName = "image"

            if let imageData = image.jpegData(compressionQuality: 0.8) {
                // Add the image data to the body
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }

            // End the body with the boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false // Stop loading indicator

                    guard let data = data, error == nil else {
                        print("Error:", error?.localizedDescription ?? "Unknown error")
                        responseText = "Error: \(error?.localizedDescription ?? "Unknown error")"
                        return
                    }

                    // Check the HTTP status code
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode != 200 {
                            print("Server returned status code:", httpResponse.statusCode)
                            responseText = "Server error: \(httpResponse.statusCode)"
                            return
                        }
                    }

                    // Parse the JSON response
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let responseTextFromServer = jsonResponse["response"] as? String {
                        responseText = responseTextFromServer
                    } else {
                        print("Invalid JSON response")
                        responseText = "Invalid response from server"
                    }
                }
            }
            task.resume()
    }
}

class AudioPlayerManager: NSObject, AVAudioPlayerDelegate {
    var audioPlayer: AVAudioPlayer?
    var onPlaybackFinished: (() -> Void)?

    func playAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error initializing audio player: \(error)")
        }
    }

    // AVAudioPlayerDelegate method
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackFinished?()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType = .camera
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let pickedImage = info[.originalImage] as? UIImage {
                parent.image = pickedImage
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Ensure the chosen source type is available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
            // Update the source type when it changes
            if UIImagePickerController.isSourceTypeAvailable(sourceType) {
                uiViewController.sourceType = sourceType
            } else {
                uiViewController.sourceType = .photoLibrary
            }
        }
}


struct ObjectDetectionView: View {
    private var prim = Color(UIColor(light: .darkPrim, dark: .darkPrim))
    private var sec = Color(UIColor(light: .lightSec, dark: .lightSec))
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var image: UIImage?
    @State private var objectDetectionViewController: ObjectDetectionViewController?

    var body: some View {
        
        VStack {
            CameraView(objectDetectionViewController: $objectDetectionViewController)
                .edgesIgnoringSafeArea(.all)
            
            // Invisible button covering the entire screen
            Button(action: {
                objectDetectionViewController?.capturePhoto()
            }) {
                Color.clear // Transparent background
                    .contentShape(Rectangle()) // Make the entire area tappable
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Cover the entire screen
            .background(Color.clear) // Ensure the button is invisible
        
        }
          
        }
    
}
// SwiftUI View to wrap the Camera Feed and Object Detection
struct CameraView: UIViewControllerRepresentable {
    @Binding var objectDetectionViewController: ObjectDetectionViewController?

    func makeUIViewController(context: Context) -> ObjectDetectionViewController {
        let viewController = ObjectDetectionViewController()
        DispatchQueue.main.async {
            self.objectDetectionViewController = viewController
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: ObjectDetectionViewController, context: Context) {}
}


import UIKit
import AVFoundation
import Vision

import UIKit
import AVFoundation
import Vision
import CoreML

func requestCameraPermission(completion: @escaping (Bool) -> Void) {
    let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    switch cameraAuthorizationStatus {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    case .denied, .restricted:
        completion(false)
    @unknown default:
        completion(false)
    }
}

class ObjectDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {

    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var sequenceRequestHandler = VNSequenceRequestHandler()
    var photoOutput: AVCapturePhotoOutput!  // Add this line
    @State private var audioPlayer: AVAudioPlayer?
    let synthesizer = AVSpeechSynthesizer()
    

    // Create a property for the model (using YOLO as an example)
    var model: VNCoreMLModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadModel()
        requestCameraPermission { granted in
                if granted {
                    self.setupCamera()
                } else {
                    fatalError("Camera access denied")
                }
            }
    }

    func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "yolo11n", withExtension: "mlmodelc") else {
            fatalError("Failed to locate the model in the app bundle")
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            guard let visionModel = try? VNCoreMLModel(for: mlModel) else {
                fatalError("Failed to create VNCoreMLModel from MLModel")
            }
            self.model = visionModel
        } catch {
            fatalError("Failed to load the model: \(error.localizedDescription)")
        }
    }

    func setupCamera() {
        captureSession = AVCaptureSession()

        // Set up camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoDeviceInput: AVCaptureDeviceInput

        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession?.canAddInput(videoDeviceInput) == true) {
            captureSession?.addInput(videoDeviceInput)
        } else {
            return
        }

        // Set up camera output
        let videoDataOutput = AVCaptureVideoDataOutput()

        if (captureSession?.canAddOutput(videoDataOutput) == true) {
            captureSession?.addOutput(videoDataOutput)

            // Set up output pixel buffer
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        } else {
            return
        }

        // Setup video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer.frame = view.layer.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer)
        
        // Initialize and set up photo output
        photoOutput = AVCapturePhotoOutput() // Initialize photoOutput
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            print("Photo output successfully added.")  // Debugging line
        } else {
            print("Could not add photo output to the session.")
            return
        }

        // Make sure the layer is resized correctly
        view.setNeedsLayout()
        view.layoutIfNeeded()

        captureSession.startRunning()
        
        if let connection = videoPreviewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .landscapeLeft
            }
        }
    }
    
    // Add a function to capture a photo
    func capturePhoto() {
        // Ensure photoOutput is not nil
        guard let photoOutput = photoOutput else {
            print("Photo output is not initialized.")
            return
        }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // Implement AVCapturePhotoCaptureDelegate method to handle the captured photo
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error: Could not get image data")
            return
        }

        // Convert the image data to UIImage
        if let image = UIImage(data: imageData) {
            // Call the function to send the image to the API
            sendImageToAPI(image: image)
        }
    }

    // Function to send the image to the API
    func sendImageToAPI(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG data")
            return
        }
        let url = URL(string: "http://10.97.229.235:5001/analyse_surroundings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let filename = "braille.jpg"
        let fieldName = "image"

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            // Add the image data to the body
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // End the body with the boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body


        // Send request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending image to API: \(error.localizedDescription)")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Response status code: \(response.statusCode)")
            }
            
            if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                    
                    // Parse the responseString as JSON
                    if let jsonData = responseString.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let description = json["description"] as? String {
                                // Pass the decoded description to fetchAndPlayAudio
                                self.fetchAndPlayAudio(text: description)
                            } else {
                                print("Failed to parse JSON or extract 'description'.")
                            }
                        } catch {
                            print("Error parsing JSON: \(error.localizedDescription)")
                        }
                    } else {
                        print("Failed to convert responseString to Data.")
                    }
                } else {
                    print("Failed to decode response data as UTF-8 string.")
                }
            }
        }

        task.resume()
        
        
    }
    

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Convert the sample buffer to a CIImage
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Create a request to detect objects using the CoreML model
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let error = error {
                print("Error performing object detection: \(error.localizedDescription)")
                return
            }

            // Handle the results
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                return
            }

            // Call the function to draw bounding boxes
            self.drawBoundingBoxes(observations: results)
        }

        // Perform the request
        do {
            try sequenceRequestHandler.perform([request], on: pixelBuffer)
        } catch {
            print("Error performing request: \(error.localizedDescription)")
        }
    }

    func drawBoundingBoxes(observations: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            // Remove previous bounding boxes
            self.view.layer.sublayers?.filter { $0.name == "boundingBoxLayer" }.forEach { $0.removeFromSuperlayer() }

            // Draw new bounding boxes
            for observation in observations {
                // Get the bounding box in view coordinates
                let boundingBox = observation.boundingBox
                let width = boundingBox.width * self.view.frame.width
                let height = boundingBox.height * self.view.frame.height
                let x = boundingBox.origin.x * self.view.frame.width
                let y = (1 - boundingBox.origin.y - boundingBox.height) * self.view.frame.height
                
                let rect = CGRect(x: x, y: y, width: width, height: height)
                
                // Create a CALayer for the bounding box
                let boxLayer = CALayer()
                boxLayer.frame = rect
                boxLayer.borderColor = UIColor.red.cgColor
                boxLayer.borderWidth = 2
                boxLayer.name = "boundingBoxLayer"  // Set a name to easily filter layers
                
                // Add the boxLayer to the view's layer
                self.view.layer.addSublayer(boxLayer)
                
                // Get the top label and confidence score
                if let topLabel = observation.labels.first {
                    let labelText = "\(topLabel.identifier) \(String(format: "%.2f", topLabel.confidence))"
                    
                    // Create a CATextLayer for the label
                    let textLayer = CATextLayer()
                    textLayer.string = labelText
                    textLayer.fontSize = 14
                    textLayer.foregroundColor = UIColor.red.cgColor
                    textLayer.backgroundColor = UIColor.white.cgColor
                    textLayer.alignmentMode = .center
                    textLayer.frame = CGRect(x: x, y: y - 20, width: width, height: 20) // Position above the bounding box
                    textLayer.name = "boundingBoxLayer"  // Set a name to easily filter layers
                    
                    // Add the textLayer to the view's layer
                    self.view.layer.addSublayer(textLayer)
                }
            }
        }
    }
    
    // Function to fetch and play audio
        func fetchAndPlayAudio(text: String) {

            let utterance = AVSpeechUtterance(string: text)
            
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-US.Samantha")
            
            synthesizer.speak(utterance)
            print("Speech started")
        

            return

//            guard let url = URL(string: "http://10.97.229.235:5001/text_to_audio") else {
//                print("Invalid URL")
//                return
//            }
//
//            let requestBody: [String: Any] = [
//                "text": text,
//                "lang": language
//            ]
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//            do {
//                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//            } catch {
//                print("Error encoding request body: \(error)")
//                return
//            }
//
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("Error: \(error.localizedDescription)")
//                    return
//                }
//
//                guard let data = data else {
//                    print("No data received")
//                    return
//                }
//                
//                
//                do {
//                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                        print("Parsed JSON Response:", json)
//                        if let audioURLString = json["audio_url"] as? String,
//                            let audioURL = URL(string: audioURLString) {
//                            // Download and play the audio file
//                            self.downloadAndPlayAudio(from: audioURL)
//                        }
//                        
//                    } else {
//                        print("Invalid JSON response")
//                    }
//                } catch {
//                    print("Error decoding JSON: \(error)")
//                }
//            }
//            task.resume()
        }
    
    func downloadAndPlayAudio(from url: URL) {
        let downloadTask = URLSession.shared.downloadTask(with: url) { tempLocalURL, response, error in
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                return
            }

            guard let tempLocalURL = tempLocalURL else {
                print("No local URL received")
                return
            }

            // Debug: Print the temporary file path
            print("Downloaded file to temporary location: \(tempLocalURL.path)")

            // Move the file to a permanent location
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let permanentURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                // Remove any existing file at the destination
                if fileManager.fileExists(atPath: permanentURL.path) {
                    try fileManager.removeItem(at: permanentURL)
                }

                // Move the file
                try fileManager.moveItem(at: tempLocalURL, to: permanentURL)
                print("File moved to permanent location: \(permanentURL.path)")

                // Configure audio session
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)

                
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                }
                
                // Initialize and play audio
                self.audioPlayer = try AVAudioPlayer(contentsOf: permanentURL)
                print(self.audioPlayer)
                self.audioPlayer?.prepareToPlay()
                if self.audioPlayer?.play() == true {
                    print("Audio is playing.")
                } else {
                    print("Audio failed to play.")
                }
            } catch {
                print("Error moving file or initializing audio player: \(error.localizedDescription)")
            }
        }
        downloadTask.resume()
    }
}



extension Data {
    mutating func append(_ string: String) {
        if let stringData = string.data(using: .utf8) {
            append(stringData)
        }
    }
}



#Preview {
    ContentView()
}


func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try AVAudioSession.sharedInstance().setActive(true)
        print("Audio session configured successfully") // Debugging
    } catch {
        print("Error configuring audio session: \(error)")
    }
}





