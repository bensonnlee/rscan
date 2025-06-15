//
//  ContentView.swift
//  R'Scan
//
//  Created by Arav Seth on 11/9/21.
//

import SwiftUI


struct MainView: View {
    @EnvironmentObject var authentication: Authentication
    
    @State private var barcode: String = ""
    @State private var isAnimating: Bool = false
    @State private var fusionKey: String = Constants.defaults.string(forKey: "fusionKey") ?? ""
    @State private var offline: Bool = false
    @State private var showingConfirmation: Bool = false
    
    let username = Constants.defaults.string(forKey: "username") ?? ""
    let password = Constants.defaults.string(forKey: "password") ?? ""
    
    var body: some View {
        ZStack() {
            // set background to navy and layer on logo at top
            Constants.navy.ignoresSafeArea()
            VStack() {
                HStack() {
                    Image("")
                        .resizable()
                        .frame(width: 50, height: 0)
                        .padding(.leading, 25)
                    Spacer()
                    Text("-|||||-")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Constants.dandelion)
                        .offset(y: Constants.titleOffset)
                    Spacer()
                    Link(destination: Constants.privacyPolicyURL) {
                            Image("Arrow")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .offset(y: Constants.arrowOffset)
                                .padding(.trailing, 25)
                    }
                }
                Spacer()
            }
            // add content on top of background and offset to keep logo
            VStack() {
                // display offline image instead of barcode if offline
                if offline {
                    Image("Offline")
                        .resizable()
                        .frame(width: Constants.screenSize.width/1.2, height: Constants.screenSize.height/2.5)
                        .padding()
                }
                else {
                    // display spinner if barcode hasn't been retrieved yet
                    if barcode.isEmpty {
                        ProgressView()
                            .scaleEffect(1.5, anchor: .center)
                            .frame(width: Constants.screenSize.width/1.2, height: Constants.screenSize.height/2.5)
                            .padding()
                    }
                    else {
                        BarCodeView(barcode: $barcode)
                            .frame(width: Constants.screenSize.width/1.2, height: Constants.screenSize.height/2.5)
                            .padding()
                    }
                }
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    manualRefresh()
                })
                {
                    // show spinner if reset barcode button is pressed
                    if isAnimating {
                        ProgressView()
                            .colorScheme(.dark)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(Constants.lightBlue)
                            .cornerRadius(10.0)
                            .padding(.bottom, 20)
                    }
                    else {
                        Text("Refresh Barcode")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(Constants.lightBlue)
                            .cornerRadius(10.0)
                            .padding(.bottom, 20)
                    }
                }
                .disabled(isAnimating)
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showingConfirmation = true
                })
                {
                    Text("Clear Credentials")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Constants.rose)
                        .cornerRadius(10.0)
                        .padding(.bottom, 20)
                }
                .confirmationDialog("Clear Credentials", isPresented: $showingConfirmation) {
                    Button("Clear Credentials", role: .destructive) {
                        logout()
                    }
                    Button("Cancel", role: .cancel) {
                        showingConfirmation = false
                    }
                } message: {
                    Text("Are you sure you want to log out?")
                }
            }
            .padding()
            .padding(.bottom, 150)
            .frame(height: Constants.screenSize.height)
            .background(Color.white)
            .offset(y: Constants.mainModalOffset)
        }
        .onAppear {
            // start timer to refresh barcodes once view appears
            startRefresh()
        }
    }
    
    func startRefresh() {
        refreshBarcode() // refresh barcode
        Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { timer in
            refreshBarcode()
        }
    }
    
    func manualRefresh() {
        isAnimating = true
        refreshBarcode()
    }

    func refreshBarcode() {
        let src128API = Src128API(username: self.username, password: self.password)
        src128API.getBarcode(fusionKey) { (response) in // call barcode endpoint and wait for completion
            // check if response is empty (indicating internal server error or failed internet conenction)
            if response.isEmpty {
                offline = true
                // sleep 1 second and call self
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // TODO: change to while loop to save resouces from recursion
                    refreshBarcode()
                }
            }
            else {
                // check if response is 401 (unauthorized)
                let authenticated: Bool? = response["authenticated"] as? Bool
                if (authenticated == false) {
                    // response is 401 and username and password are no longer valid
                    logout()
                    return
                }
                offline = false
                barcode = response["barcode_id"]! as! String
                let returnedKey = response["fusion_key"]! as! String
                if (returnedKey != fusionKey) {
                    fusionKey = returnedKey
                    Constants.defaults.set(fusionKey, forKey: "fusionKey") // save fusionKey for future requests
                }
                
                isAnimating = false
            }
        }
    }
    
    func logout() {
        // delete credentials from device
        Constants.defaults.removeObject(forKey: "username")
        Constants.defaults.removeObject(forKey: "password")
        authentication.updateValidation(loggedIn: false) // switch to login view
    }
}

extension UIImage {
    // Code128 generator image extension
    convenience init?(barcode: String) {
        let data = barcode.data(using: .ascii)
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 2, y: 2) // scale barcode up to higher resolution
        if let ciImage = filter.outputImage?.transformed(by: transform) {
            self.init(ciImage: ciImage)
        }
        else {
            return nil
        }
    }

}

struct BarCodeView: UIViewRepresentable {
    @Binding var barcode: String
    func makeUIView(context: Context) -> UIImageView {
        UIImageView()
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = UIImage(barcode: barcode) // change image to new barcode image on barcode data string update
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(Authentication())
    }
}

struct CustomCircularProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                .rotationEffect(.degrees(-90))
                .frame(width: 200)
        }
    }
}
