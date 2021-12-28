//
//  SwiftUIView.swift
//  R'Scan
//
//  Created by Arav Seth on 11/21/21.
//

import SwiftUI


struct LoginView: View {
    @EnvironmentObject var authentication: Authentication
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAnimating: Bool = false
    @State private var invalidCredentials: Bool = false
    @State private var offline: Bool = false

    var body: some View {
        ZStack() {
            // set background to navy and layer on logo at top
            Constants.navy.ignoresSafeArea()
            VStack() {
                Text("-|||||-")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.dandelion)
                    .offset(y: Constants.titleOffset)
                Spacer()
            }
            // add content on top of background and offset to keep logo
            VStack() {
                // display offline banner if offline
                if offline {
                    HStack(spacing: 0) {
                        Image("ErrorSign")
                            .resizable()
                            .frame(width: 22, height: 22, alignment: .topLeading)
                        Text("  Device Offline")
                            .foregroundColor(Color.white)
                    }
                    .cornerRadius(5.0)
                    .padding(.top, 7.5)
                    .padding(.bottom, 7.5)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10.0)
                    .ignoresSafeArea()
                }
                Spacer()
                Text("Welcome to R'Scan")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.bottom, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Login to start generating barcodes.")
                    .font(.subheadline)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("RWeb Username", text: $username)
                    .padding()
                    .background(Constants.lightGrey)
                    .cornerRadius(5.0)
                    .overlay(invalidCredentials ? RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.red, lineWidth: 1)
                             : nil)
                    .padding(.bottom, 20)
                SecureField("RWeb Password", text: $password)
                    .padding()
                    .background(Constants.lightGrey)
                    .cornerRadius(5.0)
                    .overlay(invalidCredentials ? RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.red, lineWidth: 1)
                             : nil)
                    .padding(.bottom, 20)
                Button(action: {
                    self.hideKeyboard() // dismiss keyboard
                    invalidCredentials = false // reset invalid credentials marker
                    login() // call authenticate endpoint
                })
                {
                    // show spinner if login button is pressed
                    if isAnimating {
                        ProgressView()
                            .colorScheme(.dark)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10.0)
                            .padding(.bottom, 20)
                    }
                    else {
                        Text("Verify")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10.0)
                            .padding(.bottom, 20)
                    }
                }
                .disabled(username.isEmpty || password.isEmpty || isAnimating) // prevent button press if any fields are empty
                Text("*Your credentials are not stored anywhere except for on this device")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment:.leading)
                Spacer()
            }
            .padding()
            .padding(.bottom, 150)
            .frame(height: Constants.screenSize.height)
            .background(Color.white)
            .offset(y: Constants.mainModalOffset)
        }
    }
    
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
    
    func login() {
        isAnimating = true // toggle ProgressView on
        let src128API = Src128API(username: username, password: password)
        src128API.authenticate() { (authenticated) in // call authenticate endpoint and wait for completion
            if authenticated {
                // save username and password to device if credentials are valid
                Constants.defaults.set(username, forKey: "username")
                Constants.defaults.set(password, forKey: "password")
                
                authentication.updateValidation(loggedIn: true) // switch to main view
            }
            else {
                if !Reachability.isConnectedToNetwork() {
                    offline = true // display offline banner
                }
                else {
                    offline = false
                    invalidCredentials = true // display invalid credentials marker
                }
            }
            isAnimating = false // toggle ProgressView off
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
