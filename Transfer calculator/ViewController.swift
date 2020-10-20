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
    @IBOutlet weak var kernelSizeTextField: NSTextField!
    @IBOutlet weak var dimerProbabilityTextField: NSTextField!
    
    @IBOutlet weak var donorsNumberTextField: NSTextField!
    @IBOutlet weak var acceptorsNumberTextField: NSTextField!
    @IBOutlet weak var exclusionRadiusTextField: NSTextField!
    
    @IBOutlet weak var resultsTable: NSTableView!
    
    @IBOutlet weak var generateOneParticleButton: NSButton!
    @IBAction func generateOneParticle(_ sender: AnyObject) {
        if let job = createJob(), let particule = job.generateParticule() {
            currentJob = job
            particleView.particule = particule
            calculateDistancesButton.isEnabled = true
        }
    }
    
    @IBOutlet weak var calculateDistancesButton: NSButton!
    @IBAction func calculateDistances(_ sender: AnyObject) {
        if let particule = particleView.particule {
            distancesResult = Job.calculateAllDistances(particule)
            calculateDistancesButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var repeatsNumberTextField: NSTextField!
    @IBOutlet weak var repeatCycleButton: NSButton!
    @IBAction func repeatCycle(_ sender: AnyObject) {
        if let job = createJob() {
            currentJob = job
            
            self.progressIndicator.doubleValue = 0
            self.progressIndicator.maxValue = Double(job.repeats)
            changeUIAvailability(false)
            self.setCalculatingStatus()
            self.cancelButton.isEnabled = true
            
            DispatchQueue.global(qos: .default).async {
                let _ = job.getAverageDistances(job.repeats, repeatCompletionHandler: {
                    DispatchQueue.main.async {
                        self.progressIndicator.increment(by: 1)
                        self.distancesResult = job.distancesResult
                        self.particleView.particule = job.currentParticule
                    }
                })
                
                DispatchQueue.main.async {
                    self.setAvailableStatus()
                    self.changeUIAvailability(true)
                    self.cancelButton.isEnabled = false
                }
            }
        }
    }
    
    @IBOutlet weak var relationSelector: NSPopUpButton!
    @IBOutlet weak var maxKTButton: NSButton!
    @IBAction func maxKTAsCSV(_ sender: AnyObject) {
        let relation: RelationType = (relationSelector.title == "Donor-Donor") ? .donorDonor : ((relationSelector.title == "Donor-Acceptor") ? .donorAcceptor : .acceptorAcceptor)
        
        if let job = createJob() {
            currentJob = job
            
            self.progressIndicator.doubleValue = 0
            self.progressIndicator.maxValue = Double(job.repeats)
            changeUIAvailability(false)
            self.setCalculatingStatus()
            self.cancelButton.isEnabled = true
            
            DispatchQueue.global(qos: .default).async {
                let result = job.maxKTAsCSV(relation, repeats: job.repeats, repeatCompletionHandler: {
                    DispatchQueue.main.async {
                        self.progressIndicator.increment(by: 1)
                        self.particleView.particule = job.currentParticule
                    }
                })
                
                DispatchQueue.main.async {
                    var csvData = "distance (nm), kT,\n"
                
                    for element in result {
                        csvData += "\(element.distance), \(element.kT),\n"
                    }
                
                    let saveDialog = NSSavePanel()
                
                    saveDialog.message = "Please select a path where to save the kT as a function of distance data."
                    saveDialog.allowsOtherFileTypes = false
                    saveDialog.canCreateDirectories = true
                    saveDialog.nameFieldStringValue = "untitled.csv"
                    saveDialog.title = "Saving Data..."
                
                
                    let saveResult = saveDialog.runModal()
                    
                    if saveResult.rawValue == NSFileHandlingPanelOKButton {
                        if let path = saveDialog.url?.path {
                            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
                            do {
                                try csvData.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
                                self.changeUIAvailability(true)
                            } catch let error as NSError {
                                let alert = NSAlert(error: error)
                                alert.runModal()
                            }
                        }
                    } else {
                        self.changeUIAvailability(true)
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var cancelButton: NSButton!
    @IBAction func cancelAllOperations(_ sender: AnyObject) {
        currentJob?.cancelAll()
        
        cancelButton.isEnabled = false
        cancelButton.title = "Operation canceled, please wait..."
        setUnavailableStatus()
        
        DispatchQueue.global(qos: .default).async {
            self.currentJob?.queue?.waitUntilAllOperationsAreFinished()
            self.cancelButton.title = "Cancel All Operations"
            self.setAvailableStatus()
        }
    }
    
    @IBOutlet weak var countryModeButton: NSPopUpButton!
    @IBAction func changeCountryMode(_ sender: AnyObject) {
        if countryModeButton.title == "🇮🇹" {
            particleView.donorColor = NSColor(calibratedRed: 0, green: 0.5, blue: 0, alpha: 1)
        } else {
            particleView.donorColor = NSColor.blue
        }
    }
    
    @IBOutlet weak var statusIndicator: NSImageView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    
    var distancesResult: [String: [Double]] = ["DonDon": [], "DonAcc": [], "AccAcc": []] {
        didSet {
            self.resultsTable.reloadData()
        }
    }
    
    var currentJob: Job?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        resultsTable.dataSource = self
        resultsTable.delegate = self
        
        cancelButton.isEnabled = false
        calculateDistancesButton.isEnabled = false
    }
    
    /* -----------------------------------------------------------------------
    
                                CALCULATIONS
    
    ----------------------------------------------------------------------- */
    
    func createJob() -> Job? {
        guard let radius = Double(particleSizeTextField.stringValue),
            let donors = Int(donorsNumberTextField.stringValue),
            let acceptors = Int(acceptorsNumberTextField.stringValue),
            let exclusionRadius = Double(exclusionRadiusTextField.stringValue),
            let dimerProbability = Double(dimerProbabilityTextField.stringValue),
            let repeats = Int(repeatsNumberTextField.stringValue)
            else { return nil }
        
        let job = Job()
        job.description = "UI Generated Job"
        job.particleRadius = radius
        job.donors = donors
        job.acceptors = acceptors
        job.exclusionRadius = exclusionRadius
        job.dimerProbability = dimerProbability
        job.repeats = repeats
        job.kTCalculations = (relationSelector.title == "Donor-Donor") ? .donorDonor : ((relationSelector.title == "Donor-Acceptor") ? .donorAcceptor : .acceptorAcceptor)
        job.status = .queued
        
        return job
    }
    
    
    /* -----------------------------------------------------------------------

                                UI MODIFICATION

    ----------------------------------------------------------------------- */
    
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
    
    func changeUIAvailability(_ available: Bool) {
        particleSizeTextField.isEnabled = available
        dimerProbabilityTextField.isEnabled = available
        donorsNumberTextField.isEnabled = available
        acceptorsNumberTextField.isEnabled = available
        exclusionRadiusTextField.isEnabled = available
        generateOneParticleButton.isEnabled = available
        calculateDistancesButton.isEnabled = false
        repeatsNumberTextField.isEnabled = available
        repeatCycleButton.isEnabled = available
        relationSelector.isEnabled = available
        maxKTButton.isEnabled = available
    }
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let donDon = distancesResult["DonDon"], let donAcc = distancesResult["DonAcc"], let accAcc = distancesResult["AccAcc"] else { return 0 }
        
        return max(donDon.count, donAcc.count, accAcc.count)
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        if let column = tableColumn {
            let identifier = convertFromNSUserInterfaceItemIdentifier(column.identifier)
            switch identifier {
            case "PosCol":
                return row + 1
            case "DonDonCol":
                if let donDon = distancesResult["DonDon"] {
                    if row < donDon.count {
                        return String(format: "%.02f", donDon[row])
                    }
                } else {
                    return "-"
                }
            case "DonAccCol":
                if let donAcc = distancesResult["DonAcc"] {
                    if row < donAcc.count {
                        return String(format: "%.02f", donAcc[row])
                    }
                } else {
                    return "-"
                }
            case "AccAccCol":
                if let accAcc = distancesResult["AccAcc"] {
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


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSUserInterfaceItemIdentifier(_ input: NSUserInterfaceItemIdentifier) -> String {
	return input.rawValue
}
