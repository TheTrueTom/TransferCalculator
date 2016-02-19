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
        if let job = createJob(), particule = job.generateParticule() {
            currentJob = job
            particleView.particule = particule
            calculateDistancesButton.enabled = true
        }
    }
    
    @IBOutlet weak var calculateDistancesButton: NSButton!
    @IBAction func calculateDistances(sender: AnyObject) {
        if let particule = particleView.particule {
            distancesResult = Job.calculateAllDistances(particule)
            calculateDistancesButton.enabled = false
        }
    }
    
    @IBOutlet weak var repeatsNumberTextField: NSTextField!
    @IBOutlet weak var repeatCycleButton: NSButton!
    @IBAction func repeatCycle(sender: AnyObject) {
        if let job = createJob() {
            currentJob = job
            
            self.progressIndicator.doubleValue = 0
            self.progressIndicator.maxValue = Double(job.repeats)
            changeUIAvailability(false)
            self.setCalculatingStatus()
            self.cancelButton.enabled = true
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let _ = job.getAverageDistances(job.repeats, repeatCompletionHandler: {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.progressIndicator.incrementBy(1)
                        self.distancesResult = job.distancesResult
                        self.particleView.particule = job.currentParticule
                    }
                })
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.setAvailableStatus()
                    self.changeUIAvailability(true)
                    self.cancelButton.enabled = false
                }
            }
        }
    }
    
    @IBOutlet weak var relationSelector: NSPopUpButton!
    @IBOutlet weak var maxKTButton: NSButton!
    @IBAction func maxKTAsCSV(sender: AnyObject) {
        let relation: RelationType = (relationSelector.title == "Donor-Donor") ? .DonorDonor : ((relationSelector.title == "Donor-Acceptor") ? .DonorAcceptor : .AcceptorAcceptor)
        
        if let job = createJob() {
            currentJob = job
            
            self.progressIndicator.doubleValue = 0
            self.progressIndicator.maxValue = Double(job.repeats)
            changeUIAvailability(false)
            self.setCalculatingStatus()
            self.cancelButton.enabled = true
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let result = job.maxKTAsCSV(relation, repeats: job.repeats, repeatCompletionHandler: {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.progressIndicator.incrementBy(1)
                        self.particleView.particule = job.currentParticule
                    }
                })
                
                dispatch_async(dispatch_get_main_queue()) {
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
                    
                    if saveResult == NSFileHandlingPanelOKButton {
                        if let path = saveDialog.URL?.path {
                            NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
                            do {
                                try csvData.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
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
    @IBAction func cancelAllOperations(sender: AnyObject) {
        currentJob?.cancelAll()
        
        cancelButton.enabled = false
        cancelButton.title = "Operation canceled, please wait..."
        setUnavailableStatus()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.currentJob?.queue?.waitUntilAllOperationsAreFinished()
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
    
    
    var distancesResult: [String: [Double]] = ["DonDon": [], "DonAcc": [], "AccAcc": []] {
        didSet {
            self.resultsTable.reloadData()
        }
    }
    
    var currentJob: Job?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        resultsTable.setDataSource(self)
        resultsTable.setDelegate(self)
        
        cancelButton.enabled = false
        calculateDistancesButton.enabled = false
    }
    
    /* -----------------------------------------------------------------------
    
                                CALCULATIONS
    
    ----------------------------------------------------------------------- */
    
    func createJob() -> Job? {
        guard let radius = Double(particleSizeTextField.stringValue),
            donors = Int(donorsNumberTextField.stringValue),
            acceptors = Int(acceptorsNumberTextField.stringValue),
            exclusionRadius = Double(exclusionRadiusTextField.stringValue),
            dimerProbability = Double(dimerProbabilityTextField.stringValue),
            repeats = Int(repeatsNumberTextField.stringValue)
            else { return nil }
        
        let job = Job()
        job.description = "UI Generated Job"
        job.particleRadius = radius
        job.donors = donors
        job.acceptors = acceptors
        job.exclusionRadius = exclusionRadius
        job.dimerProbability = dimerProbability
        job.repeats = repeats
        job.kTCalculations = (relationSelector.title == "Donor-Donor") ? .DonorDonor : ((relationSelector.title == "Donor-Acceptor") ? .DonorAcceptor : .AcceptorAcceptor)
        job.status = .Queued
        
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
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        guard let donDon = distancesResult["DonDon"], donAcc = distancesResult["DonAcc"], accAcc = distancesResult["AccAcc"] else { return 0 }
        
        return max(donDon.count, donAcc.count, accAcc.count)
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        if let identifier = tableColumn?.identifier {
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

