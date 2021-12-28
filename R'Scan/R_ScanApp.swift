//
//  R_ScanApp.swift
//  R'Scan
//
//  Created by Arav Seth on 11/9/21.
//

import SwiftUI

@main
struct R_ScanApp: App {
    
    @StateObject var authentication = Authentication()
    
    var body: some Scene {
        WindowGroup {
            // present login view if not authenticated else present main view
            if authentication.isValidated {
                MainView().environmentObject(authentication)
            }
            else {
                LoginView().environmentObject(authentication)
            }
        }
    }
}
