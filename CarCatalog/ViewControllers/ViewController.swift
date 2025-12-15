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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func insertDataFrom(selectedCar car: Car) {
        
    }
    
    private func getDataFromFile() {
        
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest)
            print("Is Data there already?")
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
            
            if let colorDictionary = carDictionary["color"] as? [String: Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
            }
        }
    }
    
    private func getColor(colorDictionary: [String : Float]) -> UIColor {
        guard let red = colorDictionary["red"],
              let green = colorDictionary["green"],
              let blue = colorDictionary["blue"] else { return UIColor() }
        return UIColor(
            red: CGFloat(red / 255),
            green: CGFloat(green / 255),
            blue: CGFloat(blue / 255),
            alpha: 1.0
        )
    }
    
}

