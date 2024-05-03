import SwiftUI
import Vision
import CoreML
import Foundation

struct AddItemView: View {
    @EnvironmentObject var settingDefault: SettingDefault

    var onAdd: (Item) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var itemName = ""
    @State private var expirationDateInput = ""
    @State private var showingDatePicker = false
    @State private var isShowingCameraView = false
    @State private var confirmAdd = false
    @State private var noItemName = false
    @State private var resfromtext=""
    @State private var showingBarcodeScanner = false
    @FocusState private var showingKeyBoard: Bool
    @State private var isLoading_product = false
    @State private var isLoading_date = false

    @State private var imageCapture : UIImage?
    @State private var showSheet = false
    @State private var classificationResult = ""
    @State private var classifyText = false
    @State private var classifyObject = false
    @State private var classifyDate = false
    @State private var scannedProductName = ""
    private var model: Resnet50? = try? Resnet50(configuration: MLModelConfiguration())

    var body: some View {
        VStack {
            GeometryReader { proxy in
                VStack{
                    Color.clear.frame(height: 20)
                    Text("     Add Item")
                        .font(.system(size:26, weight: .bold))
                        .foregroundColor(Color(hex: 0x535657))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                    
                    Color.clear.frame(height: 20)
                    
                    HStack{
                        TextField("", text: $itemName)
                            .focused($showingKeyBoard)
                            .placeholder(when: itemName.isEmpty) {
                                Text("Item Name")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                            }
                            .onChange(of: itemName) {
                                if itemName.count > 40 {
                                    itemName = String(itemName.prefix(40))
                                }
                            }
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(hex: 0x535657))
                        
                        if isLoading_product {
                                ProgressView()  // This shows a spinner
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                        }
                    }
                    .padding()
                

                    HStack{
                        Button(action: {
                            classifyDate = false
                            classifyText = false
                            classifyObject = true
                            showSheet = true
                        }){
                            VStack{
                                Image(systemName: "camera.viewfinder")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
//                                Text("Object\nRecognition")
//                                    .font(.system(size: 15))
                            }
                        }
                        .frame(width: 120, height: 120)
                        .foregroundColor(Color(hex: 0x535657))
                        .cornerRadius(8)
                        
                        Button(action: {
                            classifyDate = false
                            classifyText = true
                            classifyObject = false
                            showSheet = true
                        }){
                            VStack{
                                Image(systemName: "text.viewfinder")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
//                                Text("Text\nRecognition")
//                                    .font(.system(size: 15))
                            }
                        }
                        .frame(width: 120, height: 120)
                        .foregroundColor(Color(hex: 0x535657))
                        .cornerRadius(8)
                        
                        Button(action: {
                            showingBarcodeScanner = true
                        }){
                            VStack{
                                Image(systemName: "barcode.viewfinder")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
//                                Text("Barcode\nLookup")
//                                    .font(.system(size: 15))
                            }
                        }
                        .sheet(isPresented: $showingBarcodeScanner) {
                            BarCodeCameraView(scannedProductName: $itemName)
                        }
                        .frame(width: 120, height: 120)
                        .foregroundColor(Color(hex: 0x535657))
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $showSheet, onDismiss: {
                        showSheet = false
                        if let image = imageCapture{
                            if classifyText{
                                performTextRecognition(image: image)
                            } else{
                                //processImage(image: image)
                                gptVision(image: image)
                            }
                        }
                    }) {
                        ImgPicker(sourceType: .camera, selectedImage: self.$imageCapture)
                    }
                    
                    Color.clear.frame(height: 20)
                    
                    HStack{
                        TextField("", text: $expirationDateInput)
                            .focused($showingKeyBoard)
                            .keyboardType(.numberPad)
                            .onChange(of: expirationDateInput) {
                                if expirationDateInput.count > 10 {
                                    expirationDateInput = String(expirationDateInput.prefix(10))
                                }
                                var withoutHyphen = String(expirationDateInput.replacingOccurrences(of: "-", with: "").prefix(8))
                                if withoutHyphen.count > 6 {
                                    withoutHyphen.insert("-", at: expirationDateInput.index(expirationDateInput.startIndex, offsetBy: 6))
                                    expirationDateInput = withoutHyphen
                                }
                                if withoutHyphen.count > 4 {
                                    withoutHyphen.insert("-", at: expirationDateInput.index(expirationDateInput.startIndex, offsetBy: 4))
                                    expirationDateInput = withoutHyphen
                                } else {
                                    expirationDateInput = withoutHyphen
                                }
                            }
                            .placeholder(when: expirationDateInput.isEmpty) {
                                Text("Expiration Date (YYYYMMDD)")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                            }
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(hex: 0x535657))
                        
                        if isLoading_date {
                                ProgressView()  // This shows a spinner
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                        }
                    }
                    .padding()
                    
                    HStack{
                        Spacer()
                        
                        DatePicker("", selection: Binding(
                            get: {
                                dateFormatter.date(from: expirationDateInput) ?? Date()
                            },
                            set: {
                                expirationDateInput = dateFormatter.string(from: $0)
                            }
                        ), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .frame(width: 120)
                        
                        Spacer()
                        
                        Button(action: {
                            classifyDate = true
                            classifyText = true
                            classifyObject = false
                            showSheet = true
                        }){
                            VStack{
                                Image(systemName: "text.viewfinder")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)

//                                Text("Text\nRecognition")
//                                    .font(.system(size: 15))
                            }
                        }
                        .frame(width: 120, height: 120)
                        .foregroundColor(Color(hex: 0x535657))
                        .cornerRadius(8)
                        .sheet(isPresented: $showSheet, onDismiss: {
                            showSheet = false
                            if let image = imageCapture{
                                if classifyText{
                                    performTextRecognition(image: image)
                                }
                            }
                        }) {
                            ImgPicker(sourceType: .camera, selectedImage: self.$imageCapture)
                        }
                        
                        Spacer()
                    }
                    
                    Button("Confirm", action: {
                        if itemName == ""{
                            noItemName = true
                        }
                        else{
                            let newItem = createItem()
                            onAdd(newItem)
                            
                            // Save the new item to UserDefaults
                            saveItemToUserDefaults(newItem)
                            
                            // Dismiss the view
                            presentationMode.wrappedValue.dismiss()
                            
                            confirmAdd = true
                        }
                    })
                    .frame(width: 120, height: 45)
                    .foregroundColor(Color(hex: 0xdee7e7))
                    .background(Color(hex: 0x7f949f))
                    .cornerRadius(10)
                    .padding(30)
                    .alert("Missing Item Name", isPresented: $noItemName){
                        Button("OK"){
                        }
                    }
                    .alert("Item Added Successfully", isPresented: $confirmAdd){
                        Button("OK"){
                            itemName = ""
                            expirationDateInput = ""
                            showingDatePicker = false
                            isShowingCameraView = false
                            showingBarcodeScanner = false
                            confirmAdd = false
                            showSheet = false
                            classificationResult = ""
                            classifyText = false
                            classifyObject = false
                            classifyDate = false
                            scannedProductName = ""
                        }
                    }
                }
                .textFieldStyle(.automatic)
            }
        }
//        .onTapGesture {
//            // Dismiss the keyboard when tapping on a blank space
//            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//        }
        .background(Color(hex: 0xdee7e7))
        .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
            .onEnded { value in
                print(value.translation)
                switch(value.translation.width, value.translation.height) {
//                    case (...0, -30...30):  print("left swipe")
//                    case (0..., -30...30):  print("right swipe")
//                    case (-100...100, ...0):  print("up swipe")
                    case (-100...100, 0...):
//                        print("down swipe")
                        showingKeyBoard = false
                    default:  print("no clue")
                }
            }
        
        )
    }

    private func createItem() -> Item {
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: Date())

        if expirationDateInput.isEmpty {
            components.month = Calendar.current.component(.month, from: Date())
            components.day = Calendar.current.component(.day, from: Date())
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd"
            if let date = dateFormatter.date(from: expirationDateInput) {
                components.month = Calendar.current.component(.month, from: date)
                components.day = Calendar.current.component(.day, from: date)
            } else {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: expirationDateInput) {
                    components.year = Calendar.current.component(.year, from: date)
                    components.month = Calendar.current.component(.month, from: date)
                    components.day = Calendar.current.component(.day, from: date)
                }
            }
        }
        settingDefault.loadSettings()
        
        return Item(name: itemName, expirationDate: Calendar.current.date(from: components), notifyTime: settingDefault.default_notify_time, ifEnable: settingDefault.default_enable_notify, priorDay: settingDefault.default_prior_day)
    }
    
    
    private func gptVision(image: UIImage?) {
        isLoading_product = true
        
        print("GPT 4 Vision")
        
        guard let imageCapture = imageCapture else {
            print("The photo is nil")
            return
        }
        
        guard let pngImage = imageCapture.pngData() else {
            print("Cannot convert to png")
            return
        }
        
        let base64_image = pngImage.base64EncodedString()
      
        let prompt = "What is the item name in the picture, it should related to food or groceries. Please just give me the name of the item."

        let requestData: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64_image)",
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 20
        ]
   
        let apiKey = ProcessInfo.processInfo.environment["GPT_APIKEY"] ?? ""
        let apiUrl = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            print("Error serializing request data: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { isLoading_product = false }
            
            if let error = error {
                print("Error calling GPT API: \(error)")
                return
            }

            guard let data = data else {
                print("No data received from GPT-4 Vision API")
                return
            }
            if let responseString = String(data: data, encoding: .utf8) {
                  if let responseData = responseString.data(using: .utf8) {
                      do {
                          let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
                          if let choices = json?["choices"] as? [[String: Any]], let firstChoice = choices.first, let message = firstChoice["message"] as? [String: Any], let content = message["content"] as? String {
                              classificationResult = content
                              self.itemName = content
                          }
                      } catch {
                          print("Error decoding response from GPT-3.5 API: \(error)")
                      }
                  }
              } else {
                  print("Unable to decode response from GPT-3.5 API")
              }
          }.resume()
      }

    private func generateResponse(prompt: String, text: String) {
        if classifyDate{ isLoading_date = true}
        else {isLoading_product = true}
        let p = "\(prompt) here is the text string(\(text))"
        print(p)
        
        let requestData: [String: Any] = [
            "model": "gpt-3.5-turbo",
            //"model": "gpt-4",
            "messages": [
                [
                    "role": "user",
                    "content": p
                ]
            ],
            "max_tokens": 30
        ]

        let apiKey = ProcessInfo.processInfo.environment["GPT_APIKEY"] ?? ""
        let apiUrl = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            print("Error serializing request data: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { isLoading_product = false }
            defer { isLoading_date = false }
            
            if let error = error {
                print("Error calling GPT API: \(error)")
                return
            }

            guard let data = data else {
                print("No data received from GPT-3.5 API")
                return
            }
         
            if let responseString = String(data: data, encoding: .utf8) {
                  if let responseData = responseString.data(using: .utf8) {
                      do {
                          
                          let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
                          if let choices = json?["choices"] as? [[String: Any]], let firstChoice = choices.first, let message = firstChoice["message"] as? [String: Any], let content = message["content"] as? String {
                              DispatchQueue.main.async {
                                                          self.resfromtext = content
                                                          
                                                          if self.classifyDate {
                                                              if content == "N/A"{
                                                                  let dateFormatter = DateFormatter()
                                                                  dateFormatter.dateFormat = "yyyy-MM-dd"
                                                                  let currentDate = Date()
                                                                  self.expirationDateInput = dateFormatter.string(from: currentDate)
                                                              }
                                                              // Update expirationDateInput if classifying expiration date
                                                              else{
                                                                  self.expirationDateInput = self.resfromtext
                                                              }
                                                          } else {
                                                              // Update itemName if classifying item name
                                                              self.itemName = self.resfromtext
                                                          }
                                                      }
                          }
                      } catch {
                          print("Error decoding response from GPT-3.5 API: \(error)")
                      }
                  }
              } else {
                  print("Unable to decode response from GPT-3.5 API")
              }
          }.resume()
    }

    private func saveItemToUserDefaults(_ item: Item) {
        if var existingItems = UserDefaults.standard.array(forKey: "StoredItemsKey") as? [Data] {
            // Convert the item to Data
            if let itemData = try? JSONEncoder().encode(item) {
                existingItems.append(itemData)
                UserDefaults.standard.set(existingItems, forKey: "StoredItemsKey")
            }
        } else {
            // If no existing items, create a new array with the current item
            let items: [Data] = [try? JSONEncoder().encode(item)].compactMap { $0 }
            UserDefaults.standard.set(items, forKey: "StoredItemsKey")
        }
    }
    
    // obj, text recog: below===================================================
    private func performTextRecognition(image: UIImage?){
        guard let cgimage = image?.cgImage else {
            fatalError("Unable to create CGImage from UIImage")
        }
        do {
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgimage)
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                let recognizedStrings = observations.compactMap { observation in
                    // Return the string of the top VNRecognizedText instance.
                    return observation.topCandidates(1).first?.string
                }
                if self.classifyDate {
                                // If classifying expiration date, pass recognized text to GPT API with appropriate prompt
                                let prompt = "What is the expiration date of the item inside the following text? Just give me the answer like \"yyyy-mm-dd\". If the date doesn't have dd, set it as the last day of the month. If you didn't find the date or the date is invalid or there is not any text, please just return N/A."
                                self.generateResponse(prompt: prompt, text: recognizedStrings.joined(separator: ", "))
                                
                            } else {
                             
                                let prompt = "What is the food item name inside the following text?just return the name of it, for example: Milk"
                                self.generateResponse(prompt: prompt, text: recognizedStrings.joined(separator: ", "))
                                
                            }
                
            }
            try imageRequestHandler.perform([request])
        } catch {
            print("Error: \(error)")
        }
    }

    private func processImage(image: UIImage?) {
        // 確認模型是否可用
        guard let model = model else { return }
        
        // 開始一個指定大小和比例的圖形上下文
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 224, height: 224), true, 2.0)
        
        // 在圖形上下文中繪製原始圖片到指定的矩形區域內
        if let image = imageCapture{
            image.draw(in: CGRect(x: 0, y: 0, width: 224, height: 224))
        }
        
        // 從目前的圖形上下文中獲取處理後的圖片
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // 結束目前的圖形上下文
        UIGraphicsEndImageContext()
        
        // 將處理後的圖片轉換為像素緩衝區，以供模型輸入使用
        guard let pixelBuffer = newImage.toPixelBuffer(pixelFormatType: kCVPixelFormatType_32ARGB, width: 224, height: 224) else {
            return
        }
        
        // 使用模型和輸入的像素緩衝區進行預測
        guard let prediction = try? model.prediction(image: pixelBuffer) else {
            return
        }
        
        // 從預測結果中提取預測的類別標籤
        let classLabel = prediction.classLabel
        
        // 通過移除逗號之後的額外資訊，清理類別標籤
        let cleanedLabel = cleanClassLabel(classLabel)
        
        // 獲取與預測的類別標籤相對應的概率值
        let probability = prediction.classLabelProbs[classLabel] ?? 0
        
        // 將概率值格式化為百分比字串
//        _ = String(format: "%.2f%%", probability * 100)
        
        // 使用清理後的類別標籤和格式化後的概率值設定預測文字
//        classificationResult = cleanedLabel
        if self.classifyDate{
            self.expirationDateInput = cleanedLabel
        } else{
            self.itemName = cleanedLabel
        }
        
        // 清理類別標籤，通過移除逗號之後的額外資訊（如果存在）
        func cleanClassLabel(_ classLabel: String) -> String {
            if let commaIndex = classLabel.firstIndex(of: ",") {
                return String(classLabel[..<commaIndex])
            }
            return classLabel
        }
    }
    // obj recog: above===================================================
    init(onAdd: @escaping (Item) -> Void) {
            self.onAdd = onAdd
    }
}

struct AddItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddItemView(onAdd: { _ in })
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content) -> some View {
            ZStack() {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

extension UIImage {
    // transform UIImage to CVPixelBuffer
    func toPixelBuffer(pixelFormatType: OSType, width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: NSNumber] = [
            kCVPixelBufferCGImageCompatibilityKey as String: NSNumber(booleanLiteral: true),
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: NSNumber(booleanLiteral: true)
        ]
        
        // create CVPixelBuffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelFormatType, attrs as CFDictionary, &pixelBuffer)
        
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        // create CVPixelBuffer Base Address
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        // create CGContext
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        // adjust axis
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // draw graphics
        UIGraphicsPushContext(context!)
        draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        UIGraphicsPopContext()
        
        // adjust base address and return CVPixelBuffer
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
