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


struct ContentView: View {
    @State private var selectedTab = 1
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                BrailleView()
                    .tag(1)
                ObstacleView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hides the default page indicator
            
            Spacer()
            
            HStack {
                Button(action: { self.selectedTab = 1 }) {
                    VStack {
                        Image(systemName: "hand.point.up.braille.fill")
                            .font(.system(size: 24))
                            .foregroundColor(self.selectedTab == 1 ? .blue : .gray)
                        Text("Braille")
                            .font(.footnote)
                            .foregroundColor(self.selectedTab == 1 ? .blue : .gray)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: { self.selectedTab = 2 }) {
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 24))
                            .foregroundColor(self.selectedTab == 2 ? .blue : .gray)
                        Text("Location")
                            .font(.footnote)
                            .foregroundColor(self.selectedTab == 2 ? .blue : .gray)
                    }
                }
                .frame(maxWidth: .infinity)
            
            }
            .padding()
            .background(Color.white)
            .border(Color.gray.opacity(0.3), width: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

struct BrailleView: View {
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var image: UIImage?
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "accessibility")
                    .resizable() // Make it resizable to control its size
                    .scaledToFit() // Ensure the aspect ratio is maintained
                    .frame(width: 30, height: 30) // Set a specific size for the image
                    .foregroundColor(.blue)
                
                Text("Braille Reader")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Divider()
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
            } else {
                Text("No Image Selected")
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 20) {
                Button("Take Photo") {
                    self.sourceType = .camera
                    self.showImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 10)
                
                Button("Choose Photo") {
                    self.sourceType = .photoLibrary
                    self.showImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .padding()
            
            if image != nil {
                Button("Send Image") {
                    if let image = image {
                        sendImageToServer(image)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: self.$image, isPresented: self.$showImagePicker, sourceType: self.sourceType)
        }
    }
    
    // Function to send image to Flask server
    func sendImageToServer(_ image: UIImage) {
        guard let url = URL(string: "link here") else { return }
        
        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create the body for the request
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending image: \(error)")
                return
            }
            print("Image sent successfully")
        }
        task.resume()
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
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}


struct AudioPlayerView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 20) {
            Button(isPlaying ? "Stop Audio" : "Play Audio") {
                if isPlaying {
                    audioPlayer?.stop()
                    isPlaying = false
                } else {
                    fetchAndPlayAudio()
                }
            }
            .padding()
            .background(isPlaying ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    // Fetch audio data from the Flask endpoint and play it
    func fetchAndPlayAudio() {
        guard let url = URL(string: "flask url") else {
            print("Invalid URL")
            return
        }
        
        // Create a URLSession data task to retrieve the audio
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching audio: \(error.localizedDescription)")
                return
            }
            
            guard let audioData = data else {
                print("No audio data received")
                return
            }
            
            do {
                // Initialize the AVAudioPlayer with the fetched data
                self.audioPlayer = try AVAudioPlayer(data: audioData)
                self.audioPlayer?.prepareToPlay()
                
                // Ensure UI updates occur on the main thread
                DispatchQueue.main.async {
                    self.audioPlayer?.play()
                    self.isPlaying = true
                }
            } catch {
                print("Error initializing audio player: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct AudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        AudioPlayerView()
    }
}

struct ObstacleView: View {
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var image: UIImage?
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "accessibility")
                    .resizable() // Make it resizable to control its size
                    .scaledToFit() // Ensure the aspect ratio is maintained
                    .frame(width: 30, height: 30) // Set a specific size for the image
                    .foregroundColor(.blue)
                
                Text("Location")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Divider()
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
            } else {
                Text("No Image Selected")
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 20) {
                Button("Take Video") {
                    self.sourceType = .camera
                    self.showImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
        }
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





// Sending image to Flask Server

//func sendImageToServer(_ imageData: Data) {
//    let url = URL(string: "http://yourflaskserver.com/upload")! // Flask server endpoint
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    
//    let boundary = "Boundary-\(UUID().uuidString)"
//    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//    
//    var body = Data()
//    
//    // Add the image data to the body of the request
//    body.append("--\(boundary)\r\n")
//    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n")
//    body.append("Content-Type: image/jpeg\r\n\r\n")
//    body.append(imageData)
//    body.append("\r\n")
//    body.append("--\(boundary)--\r\n")
//    
//    request.httpBody = body
//    
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//        if let error = error {
//            print("Error uploading image: \(error)")
//        } else {
//            print("Image uploaded successfully")
//        }
//    }
//    
//    task.resume()
//}

/*


import SwiftUI
import Charts
import SwiftData
import Foundation
import UserNotifications


struct HomeView: View {
    
    @ObservedObject var viewModel: JournalViewModel
    
    @Environment(\.modelContext) private var context
    
    @State var isInserted = false
    
    var body: some View {
        
        //https://www.youtube.com/watch?app=desktop&v=dRdguneAh8M
        
        NavigationStack {
            
            ZStack {
                
                Color("Prim")
                    .ignoresSafeArea()// Background
                
                VStack {
                    
                    HomeNavBarView(viewModel: viewModel)
                    
                    Divider()
                    
                    //https://zenn.dev/usk2000/articles/68c4c1ec7944fe
                    
                    ScrollView {
                        LazyVGrid(columns:[GridItem(.adaptive(minimum:160))]) {
                            
                            NavigationLink {
                                StressDatePickerView(viewModel: viewModel)
                            } label: {
                                StressTileView()
                            }
                            
                            
                            // Navigationlinks for metrics
                            ForEach(viewModel.metrics, id:\.self) { metric in
                                
                                NavigationLink {
                                    metricDatePickerView(viewModel: viewModel, metric: metric)
                                } label: {
                                    metricsTileView(chosenmetric: metric) // lowercase for subscript.
                                }
                                
                            }
                            
                            NavigationLink {
                                CorrelationAnalysisView(viewModel: viewModel)
                            } label: {
                                CorrelationTileView()
                            }
                            
                        } // ScrollView
                        
                        
                    } // VStack
                    .foregroundStyle(.white)
                    .padding(5)
                    
                } // VStack
            } // ZStack
            
        } //NavigationStack
        .onAppear() {
            // TODO: delete later
            
            if isInserted == false {
                
                let testLogs = [
                    stressLog(logDate: Date().addingTimeInterval(-86400*1), stressLevel: 7, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*2), stressLevel: 3, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*3), stressLevel: 3, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*4), stressLevel: 8, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*5), stressLevel: 6, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*6), stressLevel: 5, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*7), stressLevel: 1, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*8), stressLevel: 10, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*9), stressLevel: 8, notes: "", id: UUID().uuidString),
                    stressLog(logDate: Date().addingTimeInterval(-86400*10), stressLevel: 3, notes: "", id: UUID().uuidString),
                    
                ]
                
                let date = Date()
                
                let testLogs2 = [
                    metricsLog(sleep: 3, activity: 5, diet: 4, work: 5, journal: "", logDate: date),
                    metricsLog(sleep: 5, activity: 5, diet: 2, work: 7, journal: "", logDate: date.addingTimeInterval(-86400*1)),
                    metricsLog(sleep: 7, activity: 3, diet: 5, work: 1, journal: "", logDate: date.addingTimeInterval(-86400*2)),
                    metricsLog(sleep: 1, activity: 8, diet: 8, work: 4, journal: "", logDate: date.addingTimeInterval(-86400*3)),
                    metricsLog(sleep: 10, activity: 3, diet: 5, work: 8, journal: "", logDate: date.addingTimeInterval(-86400*4)),
                    metricsLog(sleep: 4, activity: 3, diet: 2, work: 6, journal: "", logDate: date.addingTimeInterval(-86400*5)),
                    metricsLog(sleep: 5, activity: 7, diet: 8, work: 4, journal: "", logDate: date.addingTimeInterval(-86400*6)),
                    metricsLog(sleep: 5, activity: 7, diet: 8, work: 2, journal: "", logDate: date.addingTimeInterval(-86400*7)),
                    
                ]
                
                for testLog in testLogs2 {
                    context.insert(testLog)
                }
                
                for testLog in testLogs {
                    context.insert(testLog)
                }
                
            }
            
            isInserted = true
            
        }
        
    } // body
    
} // HomeView


// Top bar
struct HomeNavBarView: View {
    @ObservedObject var viewModel: JournalViewModel
    
    var body: some View {
        
        Text("Hello, \(viewModel.name)")
            .font(.systemSemiBold(20))
            .foregroundStyle(Color("Sec"))
            .padding(5)
        
    }
}

struct StressTileView: View {
    @Query(filter: stressLog.dayLog(date:Date.now)) var todaysLogs: [stressLog]
    
    var body: some View {
        ZStack {
            // make local variable to avoid repetition
            VStack {
                Text("Stress")
                    .font(.systemSemiBold(20))
                
                Divider()
                    .overlay(Color("Prim"))
                
                if todaysLogs.count > 0 { // If data available for selected day
                    
                    let avgStressString = String(format: "%.2f", stressLog.getStressAvg(dayStressLogs: todaysLogs))
                    
                    Text("\(avgStressString)")
                        .font(.system(25))
                    
                } else {
                    Text("No Data")
                        .font(.system(25))
                }
            }
        } // ZStack
        .padding(35)
        .background(Color("Tint"))
        .aspectRatio(1, contentMode:.fit)
        .clipShape(.rect(cornerRadius: 20))
        .foregroundStyle(Color("Sec"))
    }
}


struct metricsTileView: View {
    @Query(filter: metricsLog.dayLog(date:Date.now)) var todaysLog: [metricsLog]
    var chosenmetric: String
    
    var body: some View {
        
        ZStack {
            VStack {
                Text("\(chosenmetric)")
                    .font(.systemSemiBold(20))
                
                Divider()
                    .overlay(Color("Prim"))
                
                if todaysLog.count > 0 {
                    
                    Text("\(String(format: "%.2f", todaysLog[0][chosenmetric]))")
                    
                } else {
                    
                    Text("No Data")
                        .font(.system(25))
                    
                }
                
            }
            .font(.system(25))
            
        } // ZStack
        .padding(35)
        .background(Color("Tint"))
        .aspectRatio(1, contentMode:.fit)
        .clipShape(.rect(cornerRadius: 20))
        .foregroundStyle(Color("Sec"))
    }
}


struct CorrelationTileView: View {
    
    var body: some View {
        ZStack {
            // make local variable to avoid repetition
            VStack {
                Text("Correlation")
                    .font(.systemSemiBold(20))
                
                Divider()
                    .overlay(Color("Prim"))
                
                Text("Analysis")
                    .font(.system(25))
                
            }
        } // ZStack
        .padding(35)
        .background(Color("Tint"))
        .aspectRatio(1, contentMode:.fit)
        .clipShape(.rect(cornerRadius: 20))
        .foregroundStyle(Color("Sec"))
    }
}
*/

