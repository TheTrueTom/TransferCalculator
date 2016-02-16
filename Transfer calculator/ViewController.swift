//
//  ViewController.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 08/01/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var particleView: ParticleView!
    
    @IBOutlet weak var particleSizeTextField: NSTextField!
    @IBOutlet weak var dimerProbabilityTextField: NSTextField!
    
    @IBOutlet weak var donorsNumberTextField: NSTextField!
    @IBOutlet weak var acceptorsNumberTextField: NSTextField!
    @IBOutlet weak var exclusionRadiusTextField: NSTextField!
    
    @IBOutlet weak var resultsTable: NSTableView!
    
    @IBOutlet weak var generateOneParticleButton: NSButton!
    @IBAction func generateOneParticle(sender: AnyObject) {
        generateParticule()
        calculateDistancesButton.enabled = true
    }
    
    @IBOutlet weak var calculateDistancesButton: NSButton!
    @IBAction func calculateDistances(sender: AnyObject) {
        if let particule = particleView.particule {
            distancesResults = calculateAllDistances(particule)
            calculateDistancesButton.enabled = false
        }
    }
    
    @IBOutlet weak var repeatsNumberTextField: NSTextField!
    @IBOutlet weak var repeatCycleButton: NSButton!
    @IBAction func repeatCycle(sender: AnyObject) {
        if let repeatNumber = Int(repeatsNumberTextField.stringValue) {
            repeatResults.removeAll()
            repeatFullCycle(repeatNumber)
        }
    }
    
    @IBOutlet weak var relationSelector: NSPopUpButton!
    @IBOutlet weak var maxKTButton: NSButton!
    @IBAction func maxKTAsCSV(sender: AnyObject) {
        if let repeatNumber = Int(repeatsNumberTextField.stringValue) {
            let relation: RelationType = (relationSelector.title == "Donor-Donor") ? .DonorDonor : ((relationSelector.title == "Donor-Acceptor") ? .DonorAcceptor : .AcceptorAcceptor)
            
            maxKTAsCSV(relation, repeats: repeatNumber)
        }
    }
    
    @IBOutlet weak var cancelButton: NSButton!
    @IBAction func cancelAllOperations(sender: AnyObject) {
        queue.cancelAllOperations()
        cancelButton.enabled = false
        cancelButton.title = "Operation canceled, please wait..."
        setUnavailableStatus()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.queue.waitUntilAllOperationsAreFinished()
            self.cancelButton.title = "Cancel All Operations"
            self.setAvailableStatus()
        }
    }
    
    @IBOutlet weak var countryModeButton: NSPopUpButton!
    @IBAction func changeCountryMode(sender: AnyObject) {
        if countryModeButton.title == "🇮🇹" {
            particleView.donorColor = NSColor(calibratedRed: 0, green: 0.5, blue: 0, alpha: 1)
        } else {
            particleView.donorColor = NSColor.blueColor()
        }
    }
    
    @IBOutlet weak var statusIndicator: NSImageView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var distancesResults: [String: [Double]] = ["DonDon": [], "DonAcc": [], "AccAcc": []] {
        didSet {
            self.resultsTable.reloadData()
        }
    }
    
    var repeatResults = [[String: [Double]]]() {
        didSet {
            self.averageResults(repeatResults)
        }
    }
    
    var queue: NSOperationQueue! {
        didSet {
            setCalculatingStatus()
            cancelButton.enabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        resultsTable.setDataSource(self)
        resultsTable.setDelegate(self)
        
        cancelButton.enabled = false
        calculateDistancesButton.enabled = false
    }
    
    func setUnavailableStatus() {
        statusIndicator.image = NSImage(named: "NSStatusUnavailable")
        statusIndicator.toolTip = "Canceling operation"
    }
    
    func setCalculatingStatus() {
        statusIndicator.image = NSImage(named: "NSStatusPartiallyAvailable")
        statusIndicator.toolTip = "Calculating"
    }
    
    func setAvailableStatus() {
        statusIndicator.image = NSImage(named: "NSStatusAvailable")
        statusIndicator.toolTip = "Available"
    }
    
    func changeUIAvailability(available: Bool) {
        particleSizeTextField.enabled = available
        dimerProbabilityTextField.enabled = available
        donorsNumberTextField.enabled = available
        acceptorsNumberTextField.enabled = available
        exclusionRadiusTextField.enabled = available
        generateOneParticleButton.enabled = available
        calculateDistancesButton.enabled = false
        repeatsNumberTextField.enabled = available
        repeatCycleButton.enabled = available
        relationSelector.enabled = available
        maxKTButton.enabled = available
    }
    
    func generateParticule() -> Particule? {
        guard let radius = Double(particleSizeTextField.stringValue), donors = Int(donorsNumberTextField.stringValue), acceptors = Int(acceptorsNumberTextField.stringValue), exclusionRadius = Double(exclusionRadiusTextField.stringValue), dimerProbability = Double(dimerProbabilityTextField.stringValue) else { return nil }
        
        let particule = Particule(radius: radius, donors: donors, acceptors: acceptors, exclusionRadius: exclusionRadius, dimerProbability: dimerProbability)
        
        particleView.particule = particule
        
        return particule
    }
    
    func calculateAllDistances(particule: Particule, limit: Int = 10) -> [String: [Double]] {
        var result: [String: [Double]] = ["DonDon": [], "DonAcc": [], "AccAcc": []]
        
        let donDon = particule.getMeanSortedDistances(.DonorDonor, limit: limit)
        result.updateValue(donDon, forKey: "DonDon")
        
        let donAcc = particule.getMeanSortedDistances(.DonorAcceptor, limit: limit)
        result.updateValue(donAcc, forKey: "DonAcc")
        
        let accAcc = particule.getMeanSortedDistances(.AcceptorAcceptor, limit: limit)
        result.updateValue(accAcc, forKey: "AccAcc")
        
        return result
    }
    
    func repeatFullCycle(repeats: Int) {
        progressIndicator.maxValue = Double(repeats)
        progressIndicator.doubleValue = 0
        
        changeUIAvailability(false)
        
        queue = NSOperationQueue()
        
        for repetition in 1...repeats {
            let operation = NSBlockOperation(block: {
                if let particule = self.generateParticule() {
                    let preResult = self.calculateAllDistances(particule)
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.repeatResults.append(preResult)
                        
                        print("Repetition \(repetition) complete")
                        self.progressIndicator.incrementBy(1)
                    }
                }
            })
            
            queue.addOperation(operation)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.queue.waitUntilAllOperationsAreFinished()
            self.setAvailableStatus()
            self.changeUIAvailability(true)
            self.cancelButton.enabled = false
        }
    }
    
    func averageResults(source: [[String: [Double]]]) {
        var final: [String: [Double]] = ["DonDon": [], "DonAcc": [], "AccAcc": []]
        
        for repeatResult in source {
            for (key, list) in repeatResult {
                if let meanList = final[key] where !meanList.isEmpty {
                    var temp: [Double] = []
                    
                    for i in 0..<list.count {
                        temp.append(meanList[i] + list[i])
                    }
                    
                    final.updateValue(temp, forKey: key)
                }
                
                if let meanList = final[key] where meanList.isEmpty {
                    final.updateValue(list, forKey: key)
                }
            }
        }
        
        for (key, list) in final {
            var temp: [Double] = []
            
            for value in list {
                temp.append(value/Double(source.count))
            }
            
            final.updateValue(temp, forKey: key)
        }
        
        distancesResults = final
    }
    
    func maxKTAsCSV(relationType: RelationType, repeats: Int) {
        progressIndicator.maxValue = Double(repeats)
        progressIndicator.doubleValue = 0
        
        changeUIAvailability(false)
        
        var result = [(distance: Double, kT: Double)]()
        
        queue = NSOperationQueue()
        
        for repetition in 1...repeats {
            let operation = NSBlockOperation(block: {
                if let particule = self.generateParticule() {
                    let subResult = particule.getMaxKTAsFunctionOfDistance(relationType)
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        result.appendContentsOf(subResult)
                        
                        print("Repetition \(repetition) complete")
                        self.progressIndicator.incrementBy(1)
                    }
                }
            })
            
            queue.addOperation(operation)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.queue.waitUntilAllOperationsAreFinished()
            
            self.changeUIAvailability(true)
            self.setAvailableStatus()
            self.cancelButton.enabled = false
            
            var csvData = "distance (nm), kT,\n"
            
            for element in result {
                csvData += "\(element.distance), \(element.kT),\n"
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                let saveDialog = NSSavePanel()
                
                saveDialog.message = "Please select a path where to save the kT as a function of distance data."
                saveDialog.allowsOtherFileTypes = false
                saveDialog.canCreateDirectories = true
                saveDialog.nameFieldStringValue = "untitled.csv"
                saveDialog.title = "Saving Data..."
                
                let saveResult = saveDialog.runModal()
                
                if saveResult == NSFileHandlingPanelOKButton {
                    if let path = saveDialog.URL?.path {
                        NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
                        do {
                            try csvData.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
                        } catch let error as NSError {
                            let alert = NSAlert(error: error)
                            alert.runModal()
                        }
                    }
                }
            }
            
        }
        
    }
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        guard let donDon = distancesResults["DonDon"], donAcc = distancesResults["DonAcc"], accAcc = distancesResults["AccAcc"] else { return 0 }
        
        return max(donDon.count, donAcc.count, accAcc.count)
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        if let identifier = tableColumn?.identifier {
            switch identifier {
            case "PosCol":
                return row + 1
            case "DonDonCol":
                if let donDon = distancesResults["DonDon"] {
                    if row < donDon.count {
                        return String(format: "%.02f", donDon[row])
                    }
                } else {
                    return "-"
                }
            case "DonAccCol":
                if let donAcc = distancesResults["DonAcc"] {
                    if row < donAcc.count {
                        return String(format: "%.02f", donAcc[row])
                    }
                } else {
                    return "-"
                }
            case "AccAccCol":
                if let accAcc = distancesResults["AccAcc"] {
                    if row < accAcc.count {
                        return String(format: "%.02f", accAcc[row])
                    }
                } else {
                    return "-"
                }
            default:
                return nil
            }
        }
        
        return nil
    }
}

