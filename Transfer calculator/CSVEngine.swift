//
//  CSVEngine.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 18/02/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Foundation
import Cocoa

class CSVEngine {
    class func saveAsCSV(jobList: [Job]) {
        var csvString = "index, creationDate, description, particleRadius, donors, acceptors, exclusionRadius, dimerProbabilty, repeats, kTCalculations,\n"
        
        for (index, job) in jobList.enumerate() {
            csvString += "\(index), \(job.creationDate), \(job.description), \(job.particleRadius), \(job.donors), \(job.acceptors), \(job.exclusionRadius), \(job.dimerProbability), \(job.repeats), \(job.kTCalculations),\n"
        }
        
        let saveDialog = NSSavePanel()
        
        saveDialog.message = "Please select a path where to the job list as CSV."
        saveDialog.allowsOtherFileTypes = false
        saveDialog.canCreateDirectories = true
        saveDialog.nameFieldStringValue = "untitled.csv"
        saveDialog.title = "Saving Job List..."
        
        let saveResult = saveDialog.runModal()
        
        if saveResult == NSFileHandlingPanelOKButton {
            if let path = saveDialog.URL?.path {
                NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
                do {
                    try csvString.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
                } catch let error as NSError {
                    let alert = NSAlert(error: error)
                    alert.runModal()
                }
            }
        }
    }
    
    class func getJobListFromCSV() -> [Job] {
        var csvString = String()
        
        let openDialog = NSOpenPanel()
        openDialog.message = "Select CSV file from which to load the job list."
        openDialog.allowedFileTypes = ["csv"]
        openDialog.title = "Opening Job List"
        
        let openResult = openDialog.runModal()
        
        if openResult == NSFileHandlingPanelOKButton {
            if let path = openDialog.URL?.path {
                do {
                    try csvString = String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
                } catch let error as NSError {
                    let alert = NSAlert(error: error)
                    alert.runModal()
                }
            }
        }
        
        if csvString.isEmpty {
            return []
        } else {
            var jobList = [Job]()
            
            let lines = csvString.componentsSeparatedByString("\n")
            
            for i in 1..<lines.count {
                let elements = lines[i].componentsSeparatedByString(",")
                
                if !elements.isEmpty && !elements[0].isEmpty {
                    let job = Job()
                    
                    let formatter = NSDateFormatter()
                    if let date = formatter.dateFromString(elements[1]) {
                        job.creationDate = date
                    }
                    
                    job.description = elements[2]
                    
                    if let radius = Double(elements[3].stringByReplacingOccurrencesOfString(" ", withString: "")) {
                        job.particleRadius = radius
                    }
                    
                    if let donors = Int(elements[4].stringByReplacingOccurrencesOfString(" ", withString: "")) {
                        job.donors = donors
                    }
                    
                    if let acceptors = Int(elements[5].stringByReplacingOccurrencesOfString(" ", withString: "")) {
                        job.acceptors = acceptors
                    }
                    
                    if let exclusionRadius = Double(elements[6].stringByReplacingOccurrencesOfString(" ", withString: "")) {
                        job.exclusionRadius = exclusionRadius
                    }
                    
                    if let dimerProbability = Double(elements[7].stringByReplacingOccurrencesOfString(" ", withString: "")) {
                        job.dimerProbability = dimerProbability
                    }
                    
                    if let repeats = Int(elements[8].stringByReplacingOccurrencesOfString(" ", withString: "")) {
                        job.repeats = repeats
                    }
                    
                    let kTCalculations = elements[9].stringByReplacingOccurrencesOfString(" ", withString: "")
                    
                    switch kTCalculations {
                    case "None":
                        job.kTCalculations = .None
                    case "DonorDonor":
                        job.kTCalculations = .DonorDonor
                    case "DonorAcceptor":
                        job.kTCalculations = .DonorAcceptor
                    case "AcceptorAcceptor":
                        job.kTCalculations = .AcceptorAcceptor
                    default:
                        job.kTCalculations = .None
                    }
                    
                    jobList.append(job)
                }
            }
            
            return jobList
        }
    }
}