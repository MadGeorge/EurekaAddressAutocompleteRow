import Foundation
import UIKit
import Eureka
import CoreLocation

struct AddressSearchRegion {
    let center: CLLocation
    let radiusMeters: Double
}

/// Describe interface which AddressAutocompleteRow and AddressSearchTVC expect from address autocomplete API. 
/// Implement this protocol for different API.
protocol AddressSearchManager {
    /// Address row use class conformed to this protocol with this initialiser
    init()
    
    /// If set to true, Address search controller start search places in provided non nil region specified on row
    var shouldPrefetchOnStart: Bool { get set }
    
    /**
     Perform search places with specified params
     
     - Parameter text: Part of place name
     - Parameter region: Region for search. Describe center point and radius
     - Parameter complete: Callback with places
     
     **Notes:** Completion block will be executed on main thread
     */
    func search(for text: String?, region: AddressSearchRegion?, complete: @escaping ((_ result: [AddressResult]) -> Void))
    
    /**
     Used to stop current search. Completion handler will not be called.
     
     Symplest implementation – return empty result in current callback if this method called
     */
    func cancel()
}

class AddressResult: Equatable {
    let title: String
    let subTitle: String
    
    init(title: String, subTitle: String) {
        self.title = title
        self.subTitle = subTitle
    }
    
    static func ==(lhs: AddressResult, rhs: AddressResult) -> Bool {
        return lhs.subTitle == rhs.subTitle && lhs.title == rhs.title
    }
}

class AddressResultWithLocation: AddressResult {
    let location: CLLocation
    
    required init(title: String, subTitle: String, location: CLLocation) {
        self.location = location
        super.init(title: title, subTitle: subTitle)
    }
}

/// A Selector row, where user can pik address with autocomplete field
final class AddressAutocompleteRow<T: AddressSearchManager>: SelectorRow<PushSelectorCell<AddressResult>, AddressSearchTVC>, RowType {
    /// Center point and radius for search
    var searchRegion: AddressSearchRegion?
    
    var searchPlaceholder: String?
    
    /// If set to true, Address search controller start search places in provided non nil region specified on row. Default is `false`
    var shouldPreloadClosestLocations = false
    
    required init(tag: String?) {
        super.init(tag: tag)
        
        cellStyle = .subtitle
        
        var manager = T()
        manager.shouldPrefetchOnStart = shouldPreloadClosestLocations
        
        presentationMode = .show(
            controllerProvider: ControllerProvider.callback {[unowned self] in
                return AddressSearchTVC(
                    manager: manager,
                    searchRegion: self.searchRegion
                ){_ in }
            },
            onDismiss: { vc in let _ = vc.navigationController?.popViewController(animated: true) }
        )
    }
    
    override func updateCell() {
        super.updateCell()
        
        cell.textLabel?.text = value?.subTitle ?? title
        
        if value == nil {
            cell.detailTextLabel?.text = searchPlaceholder ?? L("Search for an address")
        } else {
            cell.detailTextLabel?.text = title
        }
    }
}

final class AddressSearchTVC: UITableViewController, TypedRowControllerType, UISearchResultsUpdating, UISearchControllerDelegate {
    
    var row: RowOf<AddressResult>!
    var onDismissCallback: ((UIViewController) -> ())?
    
    var resultSearchController: UISearchController!
    
    private var searchBarHolderView: UIView!
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    private var manager: AddressSearchManager!
    
    var searchRegion: AddressSearchRegion?
    
    var addresses = [AddressResult]()
    
    convenience public init(
        manager: AddressSearchManager,
        searchRegion: AddressSearchRegion?,
        callback: ((UIViewController) -> ())?)
    {
        self.init(nibName: nil, bundle: nil)
        
        self.manager = manager
        self.onDismissCallback = callback
        self.searchRegion = searchRegion
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBarHolderView = UIView()
        searchBarHolderView.translatesAutoresizingMaskIntoConstraints = false
        searchBarHolderView.backgroundColor = UIColor.black
        
        view.backgroundColor = UIColor.white
        
        definesPresentationContext = true
        
        resultSearchController = UISearchController(searchResultsController: nil)
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.isActive = true
        resultSearchController.delegate = self
        
        tableView.tableHeaderView = resultSearchController.searchBar
        tableView.tableFooterView = UIView()
        
        // Add spinner to search bar
        spinner.backgroundColor = UIColor.white
        spinner.center = CGPoint(x: 22, y: 22)
        spinner.stopAnimating()
        
        resultSearchController.searchBar.addSubview(spinner)
        
        preloadLocationsIfNeeded()
        
        if row.value != nil {
            addRightBarBtn()
        }
    }
    
    func preloadLocationsIfNeeded() {
        if manager.shouldPrefetchOnStart {
            if let region = searchRegion {
                manager.search(for: nil, region: region) {[weak self] result in
                    guard let this = self else { return }
                    
                    this.updateTable(addresses: result)
                }
            }
        }
    }
    
    func updateTable(addresses: [AddressResult]) {
        self.addresses = addresses
        self.tableView.reloadData()
    }
    
    func addRightBarBtn() {
        let btn = UIBarButtonItem(title: L("Clear"), style: .plain, target: self, action: #selector(rightBarBtnAction))
        navigationItem.rightBarButtonItem = btn
    }
    
    @objc func rightBarBtnAction() {
        row.value = nil
        onDismissCallback?(self)
    }
    
    // MARK: - UISearchResultsUpdating
    
    let intervalGuard = ActionIntervalGuard()
    
    func performSearch(with searchText: String?) {
        if let text = searchText {
            let charactersCount = text.characters.count
            if charactersCount > 2 {
                intervalGuard.perform(interval: 0.4) {[weak self] in
                    print("perform")
                    guard let this = self else { return }
                    
                    this.spinner.startAnimating()
                    this.manager.search(for: text, region: this.searchRegion) {[weak self] result in
                        guard let this = self else { return }
                        
                        this.spinner.stopAnimating()
                        this.updateTable(addresses: result)
                    }
                }
            } else if charactersCount > 0 {
                manager.cancel()
                spinner.stopAnimating()
            }
        } else {
            manager.cancel()
            spinner.stopAnimating()
        }
    }
    
    var isSearchCanceled = false
    
    func updateSearchResults(for searchController: UISearchController) {
        addresses = []
        tableView.reloadData()
        
        delayCall(0.8) {[weak self] in
            guard let this = self else { return}
            
            this.performSearch(with: searchController.searchBar.text)
        }
        
        
    }
    
    // MARK: - UITableViewController
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }
    
    let cellID = "Cell"
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: cellID)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellID)
        }
        
        let current = addresses[indexPath.row]
        cell?.textLabel?.text = current.title
        cell?.detailTextLabel?.text = current.subTitle
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = addresses[indexPath.row]
        
        row.value = current
        onDismissCallback?(self)
    }
}

// Support

class ActionIntervalGuard: NSObject {
    
    private var action: (()->Void)?
    private var timer: Timer?
    
    func perform(interval: TimeInterval, action: @escaping ()->Void) {
        self.action = action
        
        if let old = self.timer {
            old.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(task), userInfo: nil, repeats: false)
    }
    
    @objc func task() {
        self.timer?.invalidate()
        self.timer = nil
        
        self.action?()
    }
}

/// Shortcut for NSLocalizedString with empty comment
func L(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

/**
 Run closure in background
 
 Do not call UI on execution!
 */
func future(closure: @escaping ()->()) {
    let backQueue = DispatchQueue.global()
    backQueue.async(execute: closure)
}

/**
 Run closure in background after delay
 
 Do not call UI on execution!
 */
func delaiedFuture(_ delayInSeconds: Double, closure: @escaping ()->()) {
    let delay = DispatchTime.now() + delayInSeconds
    let backQueue = DispatchQueue.global()
    backQueue.asyncAfter(deadline: delay, execute: closure)
}

/**
 Run closure after delay on main thread
 
 Safe for UI calls
 */
func delayCall(_ delayInSeconds: Double, closure: @escaping()->()) {
    let delay = DispatchTime.now() + delayInSeconds
    DispatchQueue.main.asyncAfter(deadline: delay) {
        closure()
    }
}

/// Run any closure on main thread explisitly
func ui(_ closure: @escaping ()->()){
    DispatchQueue.main.async(execute: closure)
}
