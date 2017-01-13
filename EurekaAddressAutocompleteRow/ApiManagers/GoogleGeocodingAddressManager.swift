//
//  GoogleGeocodingAddressManager.swift
//  EurekaAddressAutocompleteRow
//
//  Created by MadGeorge on 13/01/2017.
//  Copyright © 2017 MadGeorge. All rights reserved.
//

import Foundation
import GooglePlaces

extension AddressSearchRegion {
    var bounds: GMSCoordinateBounds {
        let northEast = locationWithBearing(bearing: 45, distanceMeters: 3000, origin: center.coordinate);
        let southWest = locationWithBearing(bearing: 180, distanceMeters: 3000, origin: center.coordinate);
        
        let b = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        return b
    }
    
    // copypaste http://stackoverflow.com/a/26500318/1522697
    private func locationWithBearing(bearing: Double, distanceMeters: Double, origin: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6) // earth radius in meters
        
        let lat1 = origin.latitude * M_PI / 180
        let lon1 = origin.longitude * M_PI / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / M_PI, longitude: lon2 * 180 / M_PI)
    }
}

extension AddressResult {
    convenience init?(place: GMSAutocompletePrediction) {
        guard
        let name = place.attributedSecondaryText?.string
        else { return nil }
        
        self.init(title: name, subTitle: place.attributedPrimaryText.string)
    }
}

final class GoogleGeocodingAddressManager: AddressSearchManager {
    static let apiKey = "AIzaSyDlwo-NM6uEc9O49kBMkzYUkictVqR4TDo"
    
    static func initAPI() {
        GMSPlacesClient.provideAPIKey(GoogleGeocodingAddressManager.apiKey)
    }
    
    private var isCanceled = false
    
    private let placesClient = GMSPlacesClient.shared()
    
    var shouldPrefetchOnStart = false
    
    func search(for text: String?, region: AddressSearchRegion?, complete: @escaping ((_ result: [AddressResult]) -> Void)) {
        guard let text = text, text.characters.count > 0 else {
            print("Warning: GoogleGeocodingAddressManager: Google geocode address autocomplete works only with non empty strings")
            return
        }
        
        isCanceled = false
        
        var bouns: GMSCoordinateBounds?
        if let region = region {
            bouns = region.bounds
        }
        
        var addresses = [AddressResult]()
        
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        placesClient.autocompleteQuery(text, bounds: bouns, filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                print("GoogleGeocodingAddressManager: autocompleteQuery error \(error)")
            }
            
            results?.forEach {result in
                if let address = AddressResult(place: result) {
                    addresses.append(address)
                }
            }
            
            print("GoogleGeocodingAddressManager: autocompleteQuery found \(addresses.count) places")
            
            ui { complete(addresses) }
        })
    }
    
    func cancel() {
        isCanceled = true
    }
}
