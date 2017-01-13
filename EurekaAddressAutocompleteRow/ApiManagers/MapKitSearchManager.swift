//
//  MapKitSearchManager.swift
//  EurekaAddressAutocompleteRow
//
//  Created by MadGeorge on 13/01/2017.
//  Copyright © 2017 MadGeorge. All rights reserved.
//

import Foundation
import MapKit

extension AddressResultWithLocation {
    convenience init?(mapItem: MKMapItem) {
        guard
        let name = mapItem.placemark.name,
        let address = mapItem.placemark.title,
        let location = mapItem.placemark.location
        else { return nil }
        
        self.init(title: name, subTitle: address, location: location)
    }
}

final class MapKitSearchManager: AddressSearchManager {
    private var isCanceled = false
    
    var shouldPrefetchOnStart = false
    
    private var localSearch: MKLocalSearch!
    private let request = MKLocalSearchRequest()
    
    func search(for text: String?, region: AddressSearchRegion?, complete: @escaping ((_ result: [AddressResult]) -> Void)) {
        isCanceled = false
        
        request.naturalLanguageQuery = text
        
        if let region = region {
            let side = region.radiusMeters * 2
            let searchRegion = MKCoordinateRegionMakeWithDistance(region.center.coordinate, side, side)
            request.region = searchRegion
        }
        
        var addresses = [AddressResultWithLocation]()
        
        localSearch = MKLocalSearch(request: request)
        localSearch.start { searchResponse, error in
            if let error = error {
                print("MapKitSearchManager: localSearch error:", error)
            } else {
                searchResponse?.mapItems.forEach{ mapItem in
                    if let address = AddressResultWithLocation(mapItem: mapItem) {
                        addresses.append(address)
                    }
                }
            }
            
            print("MapKitSearchManager: localSearch found \(addresses.count) places")
            
            ui { complete(addresses) }
        }
        
    }
    
    func cancel() {
        isCanceled = true
    }
}
