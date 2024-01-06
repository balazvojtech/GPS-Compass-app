import UIKit
import CoreLocation
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet weak var myAltitudeLabel: UILabel!
    @IBOutlet var distanceImage: UIImageView!
    @IBOutlet var altitudeImage: UIImageView!
    @IBOutlet var timezoneLabel: UILabel!
    @IBOutlet var headingDirectionLabel: UILabel!
    @IBOutlet var timezoneImage: UIImageView!
    @IBOutlet var directionImage: UIImageView!
    @IBAction func infoButtonTapped(_ sender: UIButton) {
            // Show the pop-up when the info button is tapped
            showCustomPopup()
        }
    
    @IBAction func listButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "toSecondPage", sender: self)
    }

    func showCityList() {
        print("City list button tapped")
        let alertController = UIAlertController(title: "Select a City", message: nil, preferredStyle: .actionSheet)

        for city in capitalCities {
            let action = UIAlertAction(title: city.name, style: .default) { _ in
                // Handle city selection
                self.fillCoordinatesForCity(city)
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "toSecondPage" {
                if let cityListVC = segue.destination as? CityListViewController {
                    // Pass any data or perform setup here
                    cityListVC.didSelectCity = { [weak self] city in
                        // Handle the selected city here
                        self?.fillCoordinatesForCity(city)
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    
    var destinationCoordinate: CLLocationCoordinate2D?
    let motionManager = CMMotionManager()

    private let locationManager = CLLocationManager()

    private var myCoordinates: CLLocationCoordinate2D? = nil
    private var initialNorthAngle: CGFloat = 0.0

    override func viewDidLoad() {
            super.viewDidLoad()
            latitudeTextField.delegate = self
            longitudeTextField.delegate = self
            startDeviceMotionUpdates()

            // Set background text for the text fields
            latitudeTextField.placeholder = "Insert latitude"
            longitudeTextField.placeholder = "Insert longitude"
            
            updateInterfaceForCurrentTraitCollection()

            locationManager.delegate = self
            locationManager.startUpdatingHeading()
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
        
        if locationManager.authorizationStatus == .notDetermined {
                // Request location authorization only if not determined
                requestLocationAuthorization()
            } else if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                // Start updating location only when authorized
                locationManager.startUpdatingLocation()
            }

            // Show a welcome pop-up when the view appears
            showCustomPopup()
        }

    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            // Check if the app is launched for the first time
        if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                // Start updating location only when authorized
                locationManager.startUpdatingLocation()
            }
        }

    func showCustomPopup() {
            // Your existing pop-up code remains unchanged
            let alertController = UIAlertController(title: "Welcome to GPS Compass", message: """
                This app lets you navigate towards coordinates entered by you. It provides you with bunch of information about your destination and about your location.
                
                This app works fully without Wi-Fi except 'Timezones' feature.
                
                Distance to destination - distance calculated from your location to destination.
                
                Time difference - REQUIRES WI-FI - time difference based on timezone of your location and the destination.
                
                My altitude - altitude of your current location.
                
                Direction - direction in which are you looking right at the moment. (N, NW, NE, S, SW, SE)
                """, preferredStyle: .actionSheet)

            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)
        }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateInterfaceForCurrentTraitCollection()
            updateAltitudeImageForCurrentTraitCollection()
        }
    }

    func updateInterfaceForCurrentTraitCollection() {
        if traitCollection.userInterfaceStyle == .dark {
            // Switch to the dark mode image for distance
            distanceImage.image = UIImage(named: "distanceDarkMode")
            // Use the same image for both dark and light mode for timezone
            timezoneImage.image = UIImage(named: "timezoneDarkMode")
            // Switch to the dark mode image for direction
            directionImage.image = UIImage(named: "directionDarkMode")
        } else {
            // Switch to the original image for distance in light mode
            distanceImage.image = UIImage(named: "distanceLightMode")
            // Use the same image for both dark and light mode for timezone
            timezoneImage.image = UIImage(named: "timezoneLightMode")
            // Switch to the original image for direction in light mode
            directionImage.image = UIImage(named: "directionLightMode")
        }
    }

    func updateAltitudeImageForCurrentTraitCollection() {
        if traitCollection.userInterfaceStyle == .dark {
            // Switch to the dark mode image for altitude
            altitudeImage.image = UIImage(named: "altitudeDarkMode")
        } else {
            // Switch to the original image for altitude in light mode
            altitudeImage.image = UIImage(named: "altitudeLightMode")
        }
    }

    func checkLocationServices() {
        // Remove the authorization assignment from this function
        let authorizationStatus = locationManager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            // Do nothing here. Request authorization when needed.
            break
        case .authorizedAlways, .authorizedWhenInUse:
            DispatchQueue.main.async {
                self.locationManager.startUpdatingLocation()
            }
        case .denied, .restricted:
            // Handle case where location services are denied or restricted
            displayErrorAlert(message: "Location services are not authorized.")
        @unknown default:
            fatalError("Unhandled authorization status.")
        }
    }
    
    func requestLocationAuthorization() {
        print("Location services not determined. Requesting authorization.")
        if locationManager.authorizationStatus == .notDetermined || locationManager.authorizationStatus == .denied {
            locationManager.requestAlwaysAuthorization()
        }
    }


    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            motionManager.stopDeviceMotionUpdates()
            // Stop location updates when the view disappears
            locationManager.stopUpdatingLocation()
        }
    

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        // Check location services before validating coordinates
        checkLocationServices()
        
        // Validate coordinates
        validateCoordinates()
    }
    
    func getTimeDifference(from sourceTimeZone: TimeZone, to destinationTimeZone: TimeZone) -> String {
        let sourceOffset = sourceTimeZone.secondsFromGMT()
        let destinationOffset = destinationTimeZone.secondsFromGMT()

        let difference = (destinationOffset - sourceOffset) / 3600

        if difference > 0 {
            return String(format: "Timezone: +%d hours", difference)
        } else if difference < 0 {
            return String(format: "Timezone: %d hours", difference)
        } else {
            return "Same time zone"
        }
    }

    func getTimeZone(for coordinates: CLLocationCoordinate2D, completionHandler: @escaping (TimeZone?) -> Void) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                completionHandler(nil)
                return
            }

            guard let placemark = placemarks?.first else {
                print("No placemark found for the given coordinates.")
                completionHandler(nil)
                return
            }

            if let timeZone = placemark.timeZone {
                let userTimeZone = TimeZone.current
                let timeDifference = self.getTimeDifference(from: userTimeZone, to: timeZone)

                print("Time Difference: \(timeDifference)")
                completionHandler(timeZone)
            } else {
                print("No time zone information available.")
                completionHandler(nil)
            }
        }
    }

    private var myAngle: Double = 0.0

    func validateCoordinates() {
            guard
                let latitudeText = latitudeTextField.text, !latitudeText.isEmpty,
                let longitudeText = longitudeTextField.text, !longitudeText.isEmpty
            else {
                // Handle empty fields
                displayErrorAlert(message: "Invalid coordinates. Please enter valid latitude and longitude.")
                return
            }

            let latitude = (latitudeText as NSString).doubleValue
            let longitude = (longitudeText as NSString).doubleValue

            guard CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
                // Handle invalid coordinates
                displayErrorAlert(message: "Invalid coordinates. Please enter valid latitude and longitude.")
                return
            }

            destinationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            view.endEditing(true)

            guard let destinationCoord = destinationCoordinate else {
                displayErrorAlert(message: "Destination coordinates not set.")
                return
            }

            startDeviceMotionUpdates()
        
            locationManager.startUpdatingLocation()

            if let myCoord = self.myCoordinates {
                self.myAngle = calculateAngle(from: myCoord, to: destinationCoord)
            }
        }

    func displayErrorAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        if locationManager.authorizationStatus != .authorizedAlways && locationManager.authorizationStatus != .authorizedWhenInUse {
                   // Show an additional message for location authorization
                   alertController.message?.append("\n\nPlease enable location services for accurate results.")
               }
    }

    func startDeviceMotionUpdates() {
            if motionManager.isDeviceMotionAvailable {
                motionManager.deviceMotionUpdateInterval = 0.01
                motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                    guard let self = self else { return }

                    if let error = error {
                        print("Error updating device motion: \(error.localizedDescription)")
                        return
                    }

                    guard motion != nil else {
                        print("Motion data is nil.")
                        return
                    }

                    // Check if heading and location data are available
                    guard let heading = self.locationManager.heading?.trueHeading,
                          let destinationCoord = self.destinationCoordinate,
                          let myCoord = self.myCoordinates else {
                        print("Location or heading data is nil.")
                        return
                    }

                    let bearing = self.calculateBearing(from: myCoord, to: destinationCoord)
                    let angleFromNorth = bearing - CGFloat(heading)
                    self.updateArrowRotation(adjustedAngle: angleFromNorth)
                }
            } else {
                print("Device motion is not available")
            }
        }

    func updateArrowRotation(adjustedAngle: CGFloat) {
        // Convert degrees to radians
        let rotationAngleInRadians = adjustedAngle * CGFloat.pi / 180.0

        print("Adjusted Angle: \(adjustedAngle)")
        print("Rotation Angle (Radians): \(rotationAngleInRadians)")

        let rotationTransform = CGAffineTransform(rotationAngle: rotationAngleInRadians)
        arrowImageView.transform = rotationTransform
    }
    
    @objc func dismissKeyboard() {
            view.endEditing(true)
        }
    
    func fillCoordinatesForCity(_ city: City) {
        print("Selected city: \(city.name)")
        latitudeTextField.text = "\(city.latitude)"
        longitudeTextField.text = "\(city.longitude)"
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // You can add additional validation logic here if needed
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle authorization changes
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("Location data is nil.")
            return
        }
        
        self.myCoordinates = location.coordinate
        
        guard let destinationCoord = destinationCoordinate, let myCoord = self.myCoordinates else {
            print("Destination coordinates or my coordinates are nil.")
            return
        }
        
        if self.initialNorthAngle == 0.0 {
            self.initialNorthAngle = self.calculateAngleFromNorth(heading: locationManager.heading?.trueHeading ?? 0.0,
                                                                  destinationCoord: destinationCoord,
                                                                  myCoord: myCoord)
        }
        
        // Calculate distance
        let distance = calculateDistance(from: myCoord, to: destinationCoord)
        
        // Format distance based on magnitude
        let formattedDistance: String
        if distance < 1000.0 {
            formattedDistance = String(format: "%.0f meters", distance)
        } else {
            formattedDistance = String(format: "%.1f kilometers", distance / 1000.0)
        }
        
        // Display altitude information in the label
        let myAltitudeText = String(format: "My Altitude: %.0f meters", location.altitude)
        
        // Get destination timezone and update label
        getTimeZone(for: destinationCoord) { timeZone in
            DispatchQueue.main.async {
                if let timeZone = timeZone {
                    let timeDifference = self.getTimeDifference(from: TimeZone.current, to: timeZone)
                    self.timezoneLabel.text = "\(timeDifference)"
                } else {
                    self.timezoneLabel.text = "No information"
                }
            }
        }
        
        // Update heading direction and label
        if let heading = locationManager.heading?.trueHeading {
            let headingDirection = calculateHeadingDirection(heading: heading)
            headingDirectionLabel.text = "Direction: \(headingDirection)"
        }
        
        // Update labels
        distanceLabel.text = "Distance: \(formattedDistance)"
        myAltitudeLabel.text = myAltitudeText
        
        checkIfReachedDestination(currentLocation: myCoord, destination: destinationCoord, thresholdDistance: 6.0)
        
        print("Updated location: \(location.coordinate)")
        print("My Altitude: \(location.altitude) meters")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Update heading direction when a new heading is available
        if let heading = locationManager.heading?.trueHeading {
            let headingDirection = calculateHeadingDirection(heading: heading)
            headingDirectionLabel.text = "Direction: \(headingDirection)"
        }
    }
    
    func checkIfReachedDestination(currentLocation: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, thresholdDistance: CLLocationDistance) {
        let distance = calculateDistance(from: currentLocation, to: destination)

        if distance <= thresholdDistance {
            // Display pop-up with a completion handler
            showPopup {
                // Clear destination coordinates when the user taps OK
                self.clearDestinationCoordinates()
            }
        }
    }

    func clearDestinationCoordinates() {
        // Clear the destination coordinates
        destinationCoordinate = nil
        latitudeTextField.text = nil
        longitudeTextField.text = nil
        destinationReachedCleanup()
    }

    func destinationReachedCleanup() {
        // Additional cleanup or actions after reaching the destination
        // You can customize this method as needed
    }


    func showPopup(completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Destination Reached", message: "You have reached your destination!", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            // Call the completion handler when OK is tapped
            completion()
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

func calculateHeadingDirection(heading: CLLocationDirection) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]

        let index = Int((heading + 22.5) / 45.0) & 7
        return directions[index]
    }

extension ViewController {
    func calculateBearing(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = sourceCoordinate.latitude.toRadians()
        let lon1 = sourceCoordinate.longitude.toRadians()
        let lat2 = destinationCoordinate.latitude.toRadians()
        let lon2 = destinationCoordinate.longitude.toRadians()

        let deltaLon = lon2 - lon1

        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

        let bearing = atan2(x, y)

        return bearing.toDegrees().normalizedDegree()
    }

    func calculateAngleFromNorth(heading: CLLocationDirection, destinationCoord: CLLocationCoordinate2D, myCoord: CLLocationCoordinate2D) -> CGFloat {
        let bearing = self.calculateBearing(from: myCoord, to: destinationCoord)
        let angleFromNorth = bearing - CGFloat(heading)
        return angleFromNorth
    }

    func calculateAngle(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) -> CGFloat {
        let deltaX = destinationCoordinate.longitude - sourceCoordinate.longitude
        let deltaY = destinationCoordinate.latitude - sourceCoordinate.latitude

        let angle = atan2(deltaY, deltaX)
        let angleInDegrees = angle * (180.0 / CGFloat.pi)
        let positiveAngle = (angleInDegrees + 360).truncatingRemainder(dividingBy: 360)

        return positiveAngle
    }
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }

    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

extension CLLocationDirection {
    func normalizedDegree() -> CLLocationDirection {
        return (self + 360.0).truncatingRemainder(dividingBy: 360.0)
    }
}

func calculateDistance(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) -> CLLocationDistance {
    let R = 6371000.0 // Earth radius in meters

    let dLat = (destinationCoordinate.latitude - sourceCoordinate.latitude).toRadians()
    let dLon = (destinationCoordinate.longitude - sourceCoordinate.longitude).toRadians()

    let a = sin(dLat/2) * sin(dLat/2) + cos(sourceCoordinate.latitude.toRadians()) * cos(destinationCoordinate.latitude.toRadians()) * sin(dLon/2) * sin(dLon/2)
    let c = 2 * atan2(sqrt(a), sqrt(1-a))

    let distance = R * c
    return distance
}

struct City {
    let name: String
    let latitude: Double
    let longitude: Double
}

let capitalCities = [
    City(name: "Abu Dhabi", latitude: 24.4539, longitude: 54.3773),
    City(name: "Accra", latitude: 5.6037, longitude: -0.1870),
    City(name: "Addis Ababa", latitude: 9.1450, longitude: 40.4897),
    City(name: "Algiers", latitude: 36.7528, longitude: 3.0420),
    City(name: "Amman", latitude: 31.9496, longitude: 35.9328),
    City(name: "Amsterdam", latitude: 52.3676, longitude: 4.9041),
    City(name: "Andorra la Vella", latitude: 42.5063, longitude: 1.5218),
    City(name: "Ankara", latitude: 39.9334, longitude: 32.8597),
    City(name: "Antananarivo", latitude: -18.8792, longitude: 47.5079),
    City(name: "Apia", latitude: -13.8314, longitude: -171.7663),
    City(name: "Ashgabat", latitude: 37.9601, longitude: 58.3261),
    City(name: "Asmara", latitude: 15.3229, longitude: 38.9250),
    City(name: "Astana", latitude: 51.1796, longitude: 71.4475),
    City(name: "Athens", latitude: 37.9838, longitude: 23.7275),
    City(name: "Bamako", latitude: 12.6392, longitude: -8.0029),
    City(name: "Baku", latitude: 40.4093, longitude: 49.8671),
    City(name: "Bandar Seri Begawan", latitude: 4.9416, longitude: 114.9481),
    City(name: "Bangui", latitude: 4.3750, longitude: 18.6170),
    City(name: "Banjul", latitude: 13.4550, longitude: -16.5910),
    City(name: "Basseterre", latitude: 17.3026, longitude: -62.7177),
    City(name: "Beirut", latitude: 33.8938, longitude: 35.5018),
    City(name: "Belgrade", latitude: 44.7866, longitude: 20.4489),
    City(name: "Belmopan", latitude: 17.2534, longitude: -88.7713),
    City(name: "Bern", latitude: 46.9480, longitude: 7.4474),
    City(name: "Berlin", latitude: 52.5200, longitude: 13.4050),
    City(name: "Bishkek", latitude: 42.8746, longitude: 74.5698),
    City(name: "Bogotá", latitude: 4.7110, longitude: -74.0721),
    City(name: "Bratislava", latitude: 48.1486, longitude: 17.1077),
    City(name: "Brazzaville", latitude: -4.2634, longitude: 15.2429),
    City(name: "Bridgetown", latitude: 13.1132, longitude: -59.5988),
    City(name: "Brussels", latitude: 50.8503, longitude: 4.3517),
    City(name: "Bucharest", latitude: 44.4268, longitude: 26.1025),
    City(name: "Budapest", latitude: 47.4979, longitude: 19.0402),
    City(name: "Buenos Aires", latitude: -34.6118, longitude: -58.4173),
    City(name: "Bujumbura", latitude: -3.3818, longitude: 29.3622),
    City(name: "Cairo", latitude: 30.0330, longitude: 31.2336),
    City(name: "Canberra", latitude: -35.3075, longitude: 149.1244),
    City(name: "Caracas", latitude: 10.4910, longitude: -66.8792),
    City(name: "Castries", latitude: 14.0101, longitude: -60.9870),
    City(name: "Chisinau", latitude: 47.0104, longitude: 28.8638),
    City(name: "Colombo", latitude: 6.9271, longitude: 79.8612),
    City(name: "Conakry", latitude: 9.5092, longitude: -13.5850),
    City(name: "Copenhagen", latitude: 55.6761, longitude: 12.5683),
    City(name: "Dakar", latitude: 14.6928, longitude: -17.4467),
    City(name: "Damascus", latitude: 33.5138, longitude: 36.2765),
    City(name: "Dhaka", latitude: 23.8103, longitude: 90.4125),
    City(name: "Djibouti", latitude: 11.5806, longitude: 43.1425),
    City(name: "Dodoma", latitude: -6.1731, longitude: 35.7416),
    City(name: "Doha", latitude: 25.276987, longitude: 51.53104),
    City(name: "Dublin", latitude: 53.349805, longitude: -6.26031),
    City(name: "Dushanbe", latitude: 38.5737, longitude: 68.7738),
    City(name: "Edinburgh", latitude: 55.9533, longitude: -3.1883),
    City(name: "Funafuti", latitude: -7.1095, longitude: 179.9605),
    City(name: "Gaborone", latitude: -24.6282, longitude: 25.9231),
    City(name: "Georgetown", latitude: 6.8018, longitude: -58.1553),
    City(name: "Hanoi", latitude: 21.0285, longitude: 105.8542),
    City(name: "Harare", latitude: -17.8292, longitude: 31.0522),
    City(name: "Havana", latitude: 23.1136, longitude: -82.3666),
    City(name: "Helsinki", latitude: 60.1695, longitude: 24.9354),
    City(name: "Islamabad", latitude: 33.6844, longitude: 73.0479),
    City(name: "Jakarta", latitude: -6.2088, longitude: 106.8456),
    City(name: "Jerusalem", latitude: 31.7683, longitude: 35.2137),
    City(name: "Kabul", latitude: 34.5553, longitude: 69.2075),
    City(name: "Kampala", latitude: 0.3136, longitude: 32.5811),
    City(name: "Kathmandu", latitude: 27.7172, longitude: 85.3240),
    City(name: "Khartoum", latitude: 15.5007, longitude: 32.5599),
    City(name: "Kigali", latitude: -1.9441, longitude: 30.0619),
    City(name: "Kingston", latitude: 17.9712, longitude: -76.7928),
    City(name: "Kingstown", latitude: 13.1618, longitude: -61.2244),
    City(name: "Kinshasa", latitude: -4.4419, longitude: 15.2663),
    City(name: "Kuala Lumpur", latitude: 3.1390, longitude: 101.6869),
    City(name: "Kuwait City", latitude: 29.3759, longitude: 47.9774),
    City(name: "Libreville", latitude: 0.4180, longitude: 9.4370),
    City(name: "Lilongwe", latitude: -13.9638, longitude: 33.7741),
    City(name: "Lima", latitude: -12.0464, longitude: -77.0428),
    City(name: "Lisbon", latitude: 38.7223, longitude: -9.1393),
    City(name: "Ljubljana", latitude: 46.0569, longitude: 14.5058),
    City(name: "Lomé", latitude: 6.1228, longitude: 1.2255),
    City(name: "London", latitude: 51.509865, longitude: -0.118092),
    City(name: "Luanda", latitude: -8.8399, longitude: 13.2894),
    City(name: "Lusaka", latitude: -15.3875, longitude: 28.3228),
    City(name: "Luxembourg City", latitude: 49.611621, longitude: 6.131935),
    City(name: "Madrid", latitude: 40.416775, longitude: -3.70379),
    City(name: "Majuro", latitude: 7.0897, longitude: 171.3803),
    City(name: "Malabo", latitude: 3.7501, longitude: 8.7371),
    City(name: "Male", latitude: 4.1755, longitude: 73.5093),
    City(name: "Managua", latitude: 12.114993, longitude: -86.236174),
    City(name: "Manama", latitude: 26.228516, longitude: 50.58605),
    City(name: "Manila", latitude: 14.599512, longitude: 120.98422),
    City(name: "Maputo", latitude: -25.891968, longitude: 32.605135),
    City(name: "Maseru", latitude: -29.363219, longitude: 27.51436),
    City(name: "Mata-Utu", latitude: -13.282509, longitude: -176.176447),
    City(name: "Mexico City", latitude: 19.432608, longitude: -99.133208),
    City(name: "Minsk", latitude: 53.90454, longitude: 27.561524),
    City(name: "Monaco", latitude: 43.737411, longitude: 7.420816),
    City(name: "Monrovia", latitude: 6.290743, longitude: -10.760524),
    City(name: "Montevideo", latitude: -34.901113, longitude: -56.164531),
    City(name: "Moroni", latitude: -11.717216, longitude: 43.247315),
    City(name: "Moscow", latitude: 55.755826, longitude: 37.6173),
    City(name: "Muscat", latitude: 23.58589, longitude: 58.405923),
    City(name: "Nairobi", latitude: -1.292066, longitude: 36.821946),
    City(name: "Nassau", latitude: 25.047984, longitude: -77.355413),
    City(name: "Naypyidaw", latitude: 19.763306, longitude: 96.07851),
    City(name: "Ndjamena", latitude: 12.134846, longitude: 15.055742),
    City(name: "New Delhi", latitude: 28.613939, longitude: 77.209021),
    City(name: "Niamey", latitude: 13.511596, longitude: 2.125385),
    City(name: "Nicosia", latitude: 35.185566, longitude: 33.382276),
    City(name: "Nouakchott", latitude: 18.07353, longitude: -15.958237),
    City(name: "Nouméa", latitude: -22.255823, longitude: 166.450524),
    City(name: "Nukunonu", latitude: -9.2005, longitude: -171.848),
    City(name: "Nuuk", latitude: 64.18141, longitude: -51.694138),
    City(name: "Oslo", latitude: 59.913869, longitude: 10.752245),
    City(name: "Ottawa", latitude: 45.42153, longitude: -75.697193),
    City(name: "Ouagadougou", latitude: 12.371428, longitude: -1.51966),
    City(name: "Palikir", latitude: 6.914712, longitude: 158.161027),
    City(name: "Panama City", latitude: 9.101179, longitude: -79.402864),
    City(name: "Papeete", latitude: -17.551625, longitude: -149.558476),
    City(name: "Paramaribo", latitude: 5.852036, longitude: -55.203828),
    City(name: "Paris", latitude: 48.856614, longitude: 2.352222),
    City(name: "Perth", latitude: -31.950527, longitude: 115.860457),
    City(name: "Plymouth", latitude: 16.706523, longitude: -62.215738),
    City(name: "Podgorica", latitude: 42.43042, longitude: 19.259364),
    City(name: "Port Louis", latitude: -20.166896, longitude: 57.502332),
    City(name: "Port Moresby", latitude: -9.4438, longitude: 147.180267),
    City(name: "Port of Spain", latitude: 10.654901, longitude: -61.501926),
    City(name: "Port Vila", latitude: -17.733251, longitude: 168.327325),
    City(name: "Portland", latitude: 45.523064, longitude: -122.676483),
    City(name: "Porto-Novo", latitude: 6.496857, longitude: 2.628852),
    City(name: "Prague", latitude: 50.075538, longitude: 14.4378),
    City(name: "Praia", latitude: 14.93305, longitude: -23.513327),
    City(name: "Pristina", latitude: 42.662914, longitude: 21.165503),
    City(name: "Pyongyang", latitude: 39.039219, longitude: 125.762524),
    City(name: "Quito", latitude: -0.180653, longitude: -78.467838),
    City(name: "Rabat", latitude: 33.97159, longitude: -6.849813),
    City(name: "Ramallah", latitude: 31.9073509, longitude: 35.5354719),
    City(name: "Reykjavík", latitude: 64.126521, longitude: -21.817439),
    City(name: "Road Town", latitude: 18.428612, longitude: -64.618466),
    City(name: "Rome", latitude: 41.902784, longitude: 12.496366),
    City(name: "Roseau", latitude: 15.309168, longitude: -61.379355),
    City(name: "Saipan", latitude: 15.177801, longitude: 145.750967),
    City(name: "San José", latitude: 9.928069, longitude: -84.090725),
    City(name: "San Juan", latitude: 18.466334, longitude: -66.105722),
    City(name: "San Marino", latitude: 43.935591, longitude: 12.447281),
    City(name: "San Salvador", latitude: 13.69294, longitude: -89.218191),
    City(name: "Sana'a", latitude: 15.369445, longitude: 44.191007),
    City(name: "Santa Cruz de la Sierra", latitude: -17.783383, longitude: -63.18187),
    City(name: "Santiago", latitude: -33.44889, longitude: -70.669265),
    City(name: "Santo Domingo", latitude: 18.486058, longitude: -69.931212),
    City(name: "São Tomé", latitude: 0.330192, longitude: 6.733343),
    City(name: "Sarajevo", latitude: 43.856259, longitude: 18.413076),
    City(name: "Seoul", latitude: 37.566535, longitude: 126.977969),
    City(name: "Singapore", latitude: 1.280095, longitude: 103.850949),
    City(name: "Skopje", latitude: 41.997346, longitude: 21.427996),
    City(name: "Sofia", latitude: 42.697708, longitude: 23.321868),
    City(name: "South Pole", latitude: -90, longitude: 0),
    City(name: "Stanley", latitude: -51.697713, longitude: -57.851663),
    City(name: "St. Barthélemy", latitude: 17.896435, longitude: -62.852201),
    City(name: "St. George's", latitude: 12.056098, longitude: -61.7488),
    City(name: "St. Helier", latitude: 49.186823, longitude: -2.106568),
    City(name: "St. John's", latitude: 17.12741, longitude: -61.846772),
    City(name: "St. Kitts and Nevis", latitude: 17.357822, longitude: -62.782998),
    City(name: "St. Louis", latitude: 38.627273, longitude: -90.197889),
    City(name: "St. Petersburg", latitude: 27.767601, longitude: -82.640291),
    City(name: "Stockholm", latitude: 59.329323, longitude: 18.068581),
    City(name: "Suva", latitude: -18.124809, longitude: 178.450079),
    City(name: "Sydney", latitude: -33.868820, longitude: 151.209296),
    City(name: "Tallinn", latitude: 59.4370, longitude: 24.7536),
    City(name: "Tashkent", latitude: 41.2995, longitude: 69.2401),
    City(name: "Tbilisi", latitude: 41.7151, longitude: 44.8271),
    City(name: "Tegucigalpa", latitude: 14.0729, longitude: -87.1921),
    City(name: "Tehran", latitude: 35.6895, longitude: 51.3890),
    City(name: "Thimphu", latitude: 27.4728, longitude: 89.6393),
    City(name: "Tirana", latitude: 41.3275, longitude: 19.8187),
    City(name: "Tokyo", latitude: 35.6895, longitude: 139.6917),
    City(name: "Tripoli", latitude: 32.8872, longitude: 13.1913),
    City(name: "Tunis", latitude: 36.8065, longitude: 10.1815),
    City(name: "Ulaanbaatar", latitude: 47.9214, longitude: 106.9057),
    City(name: "Vaduz", latitude: 47.1410, longitude: 9.5209),
    City(name: "Valletta", latitude: 35.8989, longitude: 14.5146),
    City(name: "The Valley", latitude: 18.2170, longitude: -63.0578),
    City(name: "Vatican City", latitude: 41.9029, longitude: 12.4534),
    City(name: "Victoria", latitude: -4.6191, longitude: 55.4513),
    City(name: "Vienna", latitude: 48.8566, longitude: 16.3522),
    City(name: "Vientiane", latitude: 17.9757, longitude: 102.6331),
    City(name: "Vilnius", latitude: 54.6872, longitude: 25.2797),
    City(name: "Warsaw", latitude: 52.2297, longitude: 21.0122),
    City(name: "Washington, D.C.", latitude: 38.895110, longitude: -77.036370),
    City(name: "Wellington", latitude: -41.2866, longitude: 174.7756),
    City(name: "Windhoek", latitude: -22.5597, longitude: 17.0832),
    City(name: "Yamoussoukro", latitude: 6.8270, longitude: -5.2890),
    City(name: "Yaoundé", latitude: 3.8480, longitude: 11.5021),
    City(name: "Yerevan", latitude: 40.1872, longitude: 44.5152),
    City(name: "Zagreb", latitude: 45.8150, longitude: 15.9785),
    City(name: "Zürich", latitude: 47.3769, longitude: 8.5417)
]
