//
//  ViewController.swift
//  EurekaAddressAutocompleteRow
//
//  Created by MadGeorge on 12/01/2017.
//  Copyright © 2017 MadGeorge. All rights reserved.
//

import UIKit
import Eureka
import CoreLocation

/// A Selector row, where user can pik address with autocomplete field. Used Foursquare suggest completion as API.
typealias FoursquareRow = AddressAutocompleteRow<FoursquareSuggestCompletionManager>

/// A Selector row, where user can pik address with autocomplete field. Used Google Places as API.
typealias GoogleRow = AddressAutocompleteRow<GoogleGeocodingAddressManager>

/// A Selector row, where user can pik address with autocomplete field. Used MapKitSearchManager as API.
typealias MapKitRow = AddressAutocompleteRow<MapKitSearchManager>

class ViewController: FormViewController, CLLocationManagerDelegate {

    static let searchRadiusMeters = 3000.0
    
    private var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = L("Address autocomplete row")
        
        setupForm()
        
        checlLocationPermissions()
        startHandleLocation()
    }
    
    func checlLocationPermissions() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startHandleLocation() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
    }

    func setupForm() {
        form
        +++ Section()
        <<< MapKitRow("mkplaces") {
            $0.title = L("MapKit public places row")
            $0.shouldPreloadClosestLocations = true
        }
        <<< GoogleRow("gmaddresses") {
            $0.title = L("Google address autocomplete row")
        }
        <<< FoursquareRow("fqplaces") {
            $0.title = L("Foursquare public places row")
        }
    }
    
    func updateRowLocation(location: CLLocation) {
        let mkplacesRow = form.rowBy(tag: "mkplaces") as! MapKitRow
        let gmaddressesRow = form.rowBy(tag: "gmaddresses") as! GoogleRow
        let fqplacesRow = form.rowBy(tag: "fqplaces") as! FoursquareRow
        
        let region = AddressSearchRegion(center: location, radiusMeters: ViewController.searchRadiusMeters)
        
        mkplacesRow.searchRegion = region
        gmaddressesRow.searchRegion = region
        fqplacesRow.searchRegion = region
    }
    
    // MARK: - CLLocationManagerDelegate
    
    var lastUpdate: Date?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.first {
            if lastUpdate == nil || last.timestamp.timeIntervalSince(lastUpdate!) > 30 {
                lastUpdate = Date()
                updateRowLocation(location: last)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}
