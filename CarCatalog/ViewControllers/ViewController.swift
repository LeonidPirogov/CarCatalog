//
//  ViewController.swift
//  CarCatalog
//
//  Created by Leonid on 14.12.2025.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    var car: Car!
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    @IBOutlet var markLabel: UILabel!
    @IBOutlet var modelLabel: UILabel!
    @IBOutlet var carImageView: UIImageView!
    @IBOutlet var lastTimeStartedLabel: UILabel!
    @IBOutlet var numberOfTripsLabel: UILabel!
    @IBOutlet var ratingLabel: UILabel!
    @IBOutlet var myChoiceImageView: UIImageView!
    
    @IBOutlet var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.selectedSegmentTintColor = .white
            
            let whiteTitleAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            segmentedControl.setTitleTextAttributes(whiteTitleAttributes, for: .normal)
            segmentedControl.setTitleTextAttributes(blackTitleAttributes, for: .selected)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDataFromFile()
        updateSegmentedControl()
    }
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateSegmentedControl()
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate it", message: "Rate this car please", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = alertController.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func insertDataFrom(selectedCar car: Car) {
        carImageView.image = UIImage(data: car.imageData ?? Data())
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiceImageView.isHidden = !(car.myChoice)
        ratingLabel.text = "Rating: \(car.rating) / 10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        
        lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: car.lastStarted!))"
        
        segmentedControl.backgroundColor = car.tintUIColor
    }
    
    private func getDataFromFile() {
        
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        guard records == 0 else { return }
        
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"),
              let dataArray = NSArray(contentsOfFile: pathToFile) else { return }
        
        for dictionary in dataArray {
            guard let entity = NSEntityDescription.entity(forEntityName: "Car", in: context) else { assertionFailure("Car entity not found")
                continue
            }
            guard let car = NSManagedObject(entity: entity, insertInto: context) as? Car else {
                assertionFailure("Failed to create Car object")
                continue
            }
            
            guard let carDictionary = dictionary as? [String: Any] else {
                assertionFailure("Invalid car dictionary format")
                continue
            }
            
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as? Double ?? 0.0
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as? Int16 ?? 1
            car.myChoice = carDictionary["myChoice"] as? Bool ?? false
            
            guard let imageName = carDictionary["imageName"] as? String else { return assertionFailure("Image not found") }
            let image = UIImage(named: imageName)
            let imageData = image?.pngData()
            car.imageData = imageData
            
            if let tintDictionary = carDictionary["tintColorData"] as? [String: Any] {
                car.tintUIColor = getColorAny(colorDictionary: tintDictionary)
            } else {
                print("No tintColorData for:", car.mark ?? "nil")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save imported cars: \(error)")
        }
    }
    
    private func update(rating: Double) {
        car.rating = rating
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            
            alertController.addAction(okAction)
            present(alertController, animated: true)
            print(error.localizedDescription)
        }
    }
    
    private func updateSegmentedControl() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        guard let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) else { return assertionFailure("Mark entity not found") }
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark)
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func getColorAny(colorDictionary: [String: Any]) -> UIColor {
        let red = (colorDictionary["red"] as? NSNumber)?.doubleValue ?? 255
        let green = (colorDictionary["green"] as? NSNumber)?.doubleValue ?? 255
        let blue = (colorDictionary["blue"] as? NSNumber)?.doubleValue ?? 0

        return UIColor(
            red: CGFloat(red / 255.0),
            green: CGFloat(green / 255.0),
            blue: CGFloat(blue / 255.0),
            alpha: 1.0
        )
    }
}

extension Car {
    var tintUIColor: UIColor {
        get {
            guard let data = tintColorData else { return .systemYellow }

            do {
                if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                return color
                }
            } catch {
                print("Unarchive tintColor failed:", error)
            }
            return .systemYellow
        }
        set {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newValue,
                                                            requiringSecureCoding: false)
                tintColorData = data
            } catch {
                tintColorData = nil
            }
        }
    }
}
