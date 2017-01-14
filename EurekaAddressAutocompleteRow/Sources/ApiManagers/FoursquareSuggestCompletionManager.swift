//
//  FoursquareSuggestCompletionManager.swift
//  EurekaAddressAutocompleteRow
//
//  Created by MadGeorge on 13/01/2017.
//  Copyright © 2017 MadGeorge. All rights reserved.
//

import Foundation
import CoreLocation

final class FoursquareSuggestCompletionManager: AddressSearchManager {
    static let clientID = "XXX"
    static let clientSecret = "XXX"
    
    private var isCanceled = false
    
    var shouldPrefetchOnStart = false
    
    func search(for text: String?, region: AddressSearchRegion?, complete: @escaping ((_ result: [AddressResult]) -> Void)) {
        guard let text = text, text.characters.count > 0 else {
            print("Warning: FoursquareSuggestCompletionManager: Foursquare Suggest completion works only with non empty strings")
            return
        }
        
        isCanceled = false
        var params = [URLQueryItem]()
        
        if let region = region {
            let locationParam = URLQueryItem(name: "ll", value: "\(region.center.coordinate.latitude),\(region.center.coordinate.longitude)")
            let radiusParam = URLQueryItem(name: "radius", value: String(region.radiusMeters))
            params.append(locationParam)
            params.append(radiusParam)
        }
        
        let queryParam = URLQueryItem(name: "query", value: text)
        params.append(queryParam)
        
        let clientIDParam = URLQueryItem(name: "client_id", value: FoursquareSuggestCompletionManager.clientID)
        params.append(clientIDParam)
        let clientSecretParam = URLQueryItem(name: "client_secret", value: FoursquareSuggestCompletionManager.clientSecret)
        params.append(clientSecretParam)
        let versionParam = URLQueryItem(name: "v", value: "20161231")
        params.append(versionParam)
        
        var addresses = [AddressResultWithLocation]()
        
        var urlComponents = URLComponents(string: "https://api.foursquare.com/v2/venues/suggestcompletion")
        urlComponents?.queryItems = params
        let url = urlComponents!.url!
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) {[weak self] (data, response, error) in
            if let error = error {
                print("FoursquareSuggestCompletionManager: dataTask error:", error)
            }
            
            if let this = self {
                if let data = data {
                    do {
                        if let js = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            addresses = this.parseResponse(json: js)
                        }
                    } catch let e {
                        print("FoursquareSuggestCompletionManager: json serialisation error", e)
                    }
                }
            }
            
            ui { complete(addresses) }
        }
        
        task.resume()
    }
    
    func cancel() {
        isCanceled = true
    }
    
    private func parseResponse(json: [String: Any]) -> [AddressResultWithLocation] {
        var result = [AddressResultWithLocation]()
        if let response = json["response"] as? [String: Any] {
            (response["minivenues"] as? [[String: Any]])?.forEach { minivenue in
                if
                let name = minivenue["name"] as? String,
                let location = minivenue["location"] as? [String: Any]
                {
                    if
                    let lat = location["lat"] as? Double,
                    let lng = location["lng"] as? Double,
                    let city = location["city"] as? String,
                    let address = location["address"] as? String
                    {
                        var compoundAddress = [city]
                        if let state = location["state"] as? String {
                            compoundAddress.append(state)
                        }
                        compoundAddress.append(address)
                        
                        let loc = CLLocation(latitude: lat, longitude: lng)
                        let addressResult = AddressResultWithLocation(title: compoundAddress.joined(separator: ", "), subTitle: name, location: loc)
                        result.append(addressResult)
                    }
                }
            }
        }
        
        return result
    }
}
