//
//  Src128API.swift
//  R'Scan
//
//  Created by Arav Seth on 11/19/21.
//

import UIKit
import SwiftUI

// initialize response structs
struct AuthenticationResponse: Codable {
    let status_code: Int
    let error: Bool
    let message: String
    let data: Dictionary<String, Bool>
}
struct BarcodeResponse: Codable {
    let status_code: Int
    let error: Bool
    let message: String
    let data: Dictionary<String, String>
}

class Src128API {
    let username: String
    let password: String
    
    let base_url = "https://src-128.herokuapp.com"
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func authenticate(completion: @escaping (_ authenticated: Bool) -> ()) {
        // build request
        var request = URLRequest(url: URL(string: base_url+"/authenticate")!)
        
        let data: [String: String] = ["username": self.username, "password": self.password]
        let body = try? JSONSerialization.data(withJSONObject: data)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                completion(false) // send completion of false in case of error
                return
            }
            guard let data = data else {
                print("Data is empty")
                completion(false) // send completion of false in case of empty response payload
                return
            }
            do {
                // decode response into dict using struct
                let payload: AuthenticationResponse = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                completion(payload.data["authenticated"]!) // send payload data as completion
            }
            catch let parsingError {
                print(parsingError)
            }
        }
        task.resume() // send request
    }
    
    
    func getBarcode(_ fusionKey: String, completion: @escaping (_ response: Dictionary<String, Any>) -> ()) {
        //build request
        var request = URLRequest(url: URL(string: base_url+"/barcode_id")!)
        
        let data: [String: String] = ["username": self.username, "password": self.password, "fusion_key": fusionKey]
        let body = try? JSONSerialization.data(withJSONObject: data)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!)
                completion([:]) // send completion of empty dict in case of error
                return
            }
            guard let data = data else {
                print("Data is empty")
                completion([:]) // send completion of empty dict in case of empty response payload
                return
            }
            do {
                // decode response into dict using struct
                let payload: BarcodeResponse = try JSONDecoder().decode(BarcodeResponse.self, from: data)
                completion(payload.data) // send payload data as completion
            }
            catch _ {
                do {
                    // parsing error indicates unauthorized response
                    let payload: AuthenticationResponse = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                    completion(payload.data) // send payload data as completion
                }
                catch let parsingError {
                    print(parsingError)
                }
            }
        }
        task.resume() // send request
    }

}

