import UIKit

class CityListViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cityScrollView: UIScrollView!

    var allCities: [City] = []  // Store all cities
    var filteredCities: [City] = []  // Filtered cities for search

    // Closure to handle city selection
    var didSelectCity: ((City) -> Void)?

    // Declare currentY at the class level
    var currentY: CGFloat = 10.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup search bar
        searchBar.delegate = self

        // Initialize the list with all cities
        allCities = capitalCities
        filteredCities = allCities

        // Add cities to the scroll view initially
        updateCityList()
    }

    // Implement UISearchBarDelegate methods for filtering cities
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredCities = searchText.isEmpty ? allCities : allCities.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        updateCityList()
    }

    func updateCityList() {
        // Clear existing views from the scroll view
        for subview in cityScrollView.subviews {
            subview.removeFromSuperview()
        }

        // Add labels for each city to the scroll view
        currentY = 10.0 // Reset currentY
        for city in filteredCities {
            let cityLabel = UILabel()
            cityLabel.text = city.name
            cityLabel.font = UIFont.systemFont(ofSize: 16.0) // Set the font size as needed
            cityLabel.frame = CGRect(x: 10.0, y: currentY, width: cityScrollView.frame.width - 20.0, height: 30.0)
            cityLabel.isUserInteractionEnabled = true // Enable user interaction
            cityLabel.tag = filteredCities.firstIndex(of: city) ?? 0 // Set a unique tag for each label

            // Add a tap gesture recognizer to each city label
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cityLabelTapped(_:)))
            cityLabel.addGestureRecognizer(tapGesture)

            cityScrollView.addSubview(cityLabel)

            currentY += 40.0 // Adjust the spacing as needed
        }

        // Set the content size of the scroll view to allow scrolling
        cityScrollView.contentSize = CGSize(width: cityScrollView.frame.width, height: currentY + 10.0)
    }

    // Handle tap on city label
    @objc func cityLabelTapped(_ gesture: UITapGestureRecognizer) {
        if let tappedLabel = gesture.view as? UILabel {
            let index = tappedLabel.tag
            let selectedCity = filteredCities[index]
            didSelectCity(selectedCity)
        }
    }

    // Handle city selection
    // Handle city selection
    func didSelectCity(_ city: City) {
        // Notify the closure with the selected city
        didSelectCity?(city)

        // Dismiss the CityListViewController
        dismiss(animated: true, completion: nil)
    }
}

extension City: Equatable {
    static func == (lhs: City, rhs: City) -> Bool {
        // Compare cities based on your equality criteria
        return lhs.name == rhs.name && lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
