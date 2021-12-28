//
//  Authentication.swift
//  R'Scan
//
//  Created by Arav Seth on 11/28/21.
//

import SwiftUI

class Authentication: ObservableObject {
    // class to store published var used for changing views
    @Published var isValidated = (UserDefaults.standard.string(forKey: "username") != nil)
    
    func updateValidation(loggedIn: Bool) {
        isValidated = loggedIn
    }
}
