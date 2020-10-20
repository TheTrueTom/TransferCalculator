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
    class func saveAsCSV(_ jobList: [Job]) {
        var csvString = "index, creationDate, description, particleRadius, donors, acceptors, exclusionRadius, dimerProbabilty, repeats, kTCalculations,\n"
        
        for (index, job) in jobList.enumerated() {
            csvString += "\(index), \(job.creationDate), \(job.description), \(job.particleRadius), \(job.donors), \(job.acceptors), \(job.exclusionRadius), \(job.dimerProbability), \(job.repeats), \(job.kTCalculations),\n"
        }
        
        let saveDialog = NSSavePanel()
        
        saveDialog.message = "Please select a path where to the job list as CSV."
        saveDialog.allowsOtherFileTypes = false
        saveDialog.canCreateDirectories = true
        saveDialog.nameFieldStringValue = "untitled.csv"
        saveDialog.title = "Saving Job List..."
        
        let saveResult = saveDialog.runModal()
        
        if saveResult.rawValue == NSFileHandlingPanelOKButton {
            if let path = saveDialog.url?.path {
                FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
                do {
                    try csvString.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
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
        
        if openResult.rawValue == NSFileHandlingPanelOKButton {
            if let path = openDialog.url?.path {
                do {
                    try csvString = String(contentsOfFile: path, encoding: String.Encoding.utf8)
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
            
            let lines = csvString.components(separatedBy: "\n")
            
            for i in 1..<lines.count {
                let elements = lines[i].components(separatedBy: ",")
                
                if !elements.isEmpty && !elements[0].isEmpty {
                    let job = Job()
                    
                    let formatter = DateFormatter()
                    if let date = formatter.date(from: elements[1]) {
                        job.creationDate = date
                    }
                    
                    job.description = elements[2]
                    
                    if let radius = Double(elements[3].replacingOccurrences(of: " ", with: "")) {
                        job.particleRadius = radius
                    }
                    
                    if let donors = Int(elements[4].replacingOccurrences(of: " ", with: "")) {
                        job.donors = donors
                    }
                    
                    if let acceptors = Int(elements[5].replacingOccurrences(of: " ", with: "")) {
                        job.acceptors = acceptors
                    }
                    
                    if let exclusionRadius = Double(elements[6].replacingOccurrences(of: " ", with: "")) {
                        job.exclusionRadius = exclusionRadius
                    }
                    
                    if let dimerProbability = Double(elements[7].replacingOccurrences(of: " ", with: "")) {
                        job.dimerProbability = dimerProbability
                    }
                    
                    if let repeats = Int(elements[8].replacingOccurrences(of: " ", with: "")) {
                        job.repeats = repeats
                    }
                    
                    let kTCalculations = elements[9].replacingOccurrences(of: " ", with: "")
                    
                    switch kTCalculations {
                    case "None":
                        job.kTCalculations = .none
                    case "DonorDonor":
                        job.kTCalculations = .donorDonor
                    case "DonorAcceptor":
                        job.kTCalculations = .donorAcceptor
                    case "AcceptorAcceptor":
                        job.kTCalculations = .acceptorAcceptor
                    default:
                        job.kTCalculations = .none
                    }
                    
                    jobList.append(job)
                }
            }
            
            return jobList
        }
    }
}
