//
//  Global.swift
//  R'Scan
//
//  Created by Arav Seth on 12/3/21.
//

import SystemConfiguration
import SwiftUI

struct Constants {
    static let defaults = UserDefaults.standard
    static let screenSize = UIScreen.main.bounds
    static let titleOffset = screenSize.height == 667.0 ? 8 : UIScreen.main.bounds.height/33
    static let arrowOffset = screenSize.height == 667.0 ? 10 : UIScreen.main.bounds.height/31.5
    static let mainModalOffset = UIScreen.main.bounds.height/10
    
    static let lightGrey = Color(red: 239.0/255.0,
                                      green: 243.0/255.0,
                                      blue: 244.0/255.0)
    static let navy: Color = Color(red: 1/255.0,
                                    green: 62/255.0,
                                    blue: 164/255.0)
    static let dandelion: Color = Color(red: 255/255.0,
                                         green: 183/255.0,
                                         blue: 28/255.0)
    static let lightBlue: Color = Color(red: 0/255.0,
                                         green: 150/255.0,
                                         blue: 255/255.0)
    static let rose: Color = Color(red: 255/255.0,
                                   green: 40/255.0,
                                   blue: 50/255.0)
    
    static let privacyPolicyURL: URL = URL(string: "https://kozzza.github.io/rscan.github.io/")!
    
 }

public class Reachability {

    class func isConnectedToNetwork() -> Bool {

        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }

        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        return ret
    }
}
