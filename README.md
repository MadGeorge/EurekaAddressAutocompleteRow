# Address autocomplite row for Eureka form buider
<p align="center">
<img width="350" src="https://github.com/MadGeorge/EurekaAddressAutocompliteRow/raw/master/ReadmeResources/screencast.gif" /> <img width="350" src="https://github.com/MadGeorge/EurekaAddressAutocompliteRow/raw/master/ReadmeResources/scr1.jpg" /> <img width="350" src="https://github.com/MadGeorge/EurekaAddressAutocompliteRow/raw/master/ReadmeResources/scr2.jpg" />  <img width="350" src="https://github.com/MadGeorge/EurekaAddressAutocompliteRow/raw/master/ReadmeResources/scr3.jpg" />  <img width="350" src="https://github.com/MadGeorge/EurekaAddressAutocompliteRow/raw/master/ReadmeResources/scr4.jpg" />  <img width="350" src="https://github.com/MadGeorge/EurekaAddressAutocompliteRow/raw/master/ReadmeResources/scr5.jpg" />
</p>

### Description
Use this row to provide user input field with address or neares place autocomplete.
Usage example in `Screens/ViewController.swift`

### Requirements 
Testet with iOS 9+, developed with Xcode 8.2.1

### How to use
1. Install Eureka with [instructions](https://github.com/xmartlabs/Eureka#installation).
2. Add `AddressRowAndSupport.swift` into project
3. Select which API you want to use

**Google Places**
1. Drop `GoogleGeocodingAddressManager.swift` into project
2. Get API key for Google Places and fill in `GoogleGeocodingAddressManager.apiKey`

**Foursquare**
1. Drop `FoursquareSuggestCompletionManager.swift` into project
2. Get `client_id` and `client_secret` from foursquare developers web site and fill in `FoursquareSuggestCompletionManager.clientID` and `FoursquareSuggestCompletionManager.clientSecret`

**MapKit**
MapKit provide
Drop `MapKitSearchManager.swift` into project
