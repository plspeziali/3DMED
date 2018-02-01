//
//  getJson.swift
//  3DMED
//
//  Created by Paolo Speziali and Marcelo Levano on 18/09/17.
//

import Foundation
import Alamofire

class Networking {
    private let website = "http://speziapi.altervista.org"
    private let json = "/outJson.php"
    private var reachability = Reachability()
    
    private func path() -> String {
        return "\(website)\(json)"
    }
    
    func request(prediction: String, completion: @escaping ([Any]) ->() ) {
        let parameters: Parameters = ["prediction" : prediction]
        if (reachability.manager?.isReachable)! {
            print("Rete disponibile!")
            Alamofire.request(path(), method: .post, parameters: parameters).responseJSON { (response) in
                if (response.result.value != nil){
                    completion(response.result.value as! [Any])
                }
                else{ print ("frego")}
            }
        }
        else {
            print("Rete non disponibile!")
        }
    }
    
}

class CategoryDealer {
    private let website = "http://speziapi.altervista.org"
    private let json = "/outCategories.php"
    private var reachability = Reachability()
    
    private func path() -> String {
        return "\(website)\(json)"
    }
    
    func request(completion: @escaping ([Any]) ->() ) {
        if (reachability.manager?.isReachable)! {
            print("Rete disponibile!")
            Alamofire.request(path(), method: .post).responseJSON { (response) in
                completion(response.result.value as! [Any])
            }
        }
        else {
            print("Rete non disponibile!")
        }
    }
    
}

class Reachability {
    var manager = NetworkReachabilityManager(host: "www.google.com")
    func networkStatus() {
        manager?.listener = { status in
            print("status della rete: \(status)")
        }
        manager?.startListening()
    }
}
