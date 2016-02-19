//
//  SummaryBuilder.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 17/02/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Foundation
import Cocoa

class SummaryBuilder {
    
    class func createReport(jobList: [Job], url: NSURL) {
        guard let newPath = NSURL(string: "Report.html", relativeToURL: url)?.path else { return }
        
        var result = SummaryBuilder.createHeader()
        result += SummaryBuilder.createAllExperiments(jobList, url: url)
        result += SummaryBuilder.createFooter()
        
        NSFileManager.defaultManager().createFileAtPath(newPath, contents: nil, attributes: nil)
        
        do {
            try result.writeToFile(newPath, atomically: true, encoding: NSUTF8StringEncoding)
            //NSWorkspace.sharedWorkspace().openFile(newPath)
        } catch let error as NSError {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    
    private class func createHeader() -> String {
        var string = String()
    
        if let path = NSBundle.mainBundle().pathForResource("model-header", ofType: "txt") {
        
            do {
                try string = String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            } catch let error as NSError {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
        
        return string
    }
    
    private class func createAllExperiments(jobList: [Job], url: NSURL) -> String {
        var string = String()
        
        for (index, job) in jobList.enumerate() {
            string += createExperiment(job, index: index, url: url)
        }
        
        return string
    }
    
    private class func createExperiment(job: Job, index: Int, url: NSURL) -> String {
        var string = "<div class='experiment'>"
        string += "<h2>Experiment #\(index + 1)</h2>"
        string += "<p>\(job.description)</p>"
        string += "<h3>Parameters</h3>"
        string += SummaryBuilder.createParameters(job)
        
        string += "<h3>Distances</h3>"
        string += SummaryBuilder.createDistances(job.distancesResult)
        
        string += "<h3>kT</h3>"
        string += SummaryBuilder.createkT(job, url: url, index: index)
        
        string += "</div>"
        
        return string
    }
    
    private class func createParameters(job: Job) -> String {
        var string = "<table class='parameters'><tbody>"
        string += "<tr><td>Particle Radius</td><td>\(job.particleRadius) nm</td><td>Exclusion Radius</td><td>\(job.exclusionRadius) nm</td></tr>"
        string += "<tr><td># Donors</td><td>\(job.donors)</td><td># Acceptors</td><td>\(job.acceptors)</td></tr>"
        string += "<tr><td>Dimer probability</td><td>\(job.dimerProbability * 100) %</td><td>Repeats</td><td>\(job.repeats)</td></tr>"
        string += "</tbody></table>"
        return string
    }
    
    private class func createDistances(distanceResults: DistancesResult) -> String {
        guard var donDon = distanceResults["DonDon"], var donAcc = distanceResults["DonAcc"], var accAcc = distanceResults["AccAcc"] else { return "<p>No distance results available</p>" }
        
        let maximum = max(donDon.count, donAcc.count, accAcc.count)
        
        if maximum == 0 {
            return "<p>No distance results available</p>"
        }
        
        var zerosToAdd = [Int]()
        
        for array in [donDon, donAcc, accAcc] {
            zerosToAdd.append(maximum - array.count)
        }
        
        for _ in 0...zerosToAdd[0] {
            donDon.append(0)
        }
        
        for _ in 0...zerosToAdd[1] {
            donAcc.append(0)
        }
        
        for _ in 0...zerosToAdd[2] {
            accAcc.append(0)
        }
        
        var string = String()
        
        if distanceResults.isEmpty {
            string += "<p>No distance results available</p>"
        } else {
            string += "<table class='result'><tbody><tr><td>&nbsp;</td><td>Donor-Donor (nm)</td><td>Donor-Acceptor (nm)</td><td>Acceptor-Acceptor (nm)</td></tr>"
            
            for i in 1...maximum {
                string += "<tr><td>\(i)</td>"
                string += "<td>" + ((donDon[i-1] == 0) ? "" : String(format: "%.02f", donDon[i-1])) + "</td>"
                string += "<td>" + ((donAcc[i-1] == 0) ? "" : String(format: "%.02f", donAcc[i-1])) + "</td>"
                string += "<td>" + ((accAcc[i-1] == 0) ? "" : String(format: "%.02f", accAcc[i-1])) + "</td>"
                string += "</tr>"
            }
            
            string += "</tbody></table>"
        }
        
        return string
    }
    
    private class func createkT(job: Job, url: NSURL, index: Int) -> String {
        let kTResults = job.kTResult
        
        var string = String()
        
        if kTResults.isEmpty {
            string += "<p>No kT results available</p>"
        } else {
            var csvData = "distance (nm), kT,\n"
            
            for element in kTResults {
                csvData += "\(element.distance), \(element.kT),\n"
            }
            
            guard let newPath = NSURL(string: "Experiment\(index).csv", relativeToURL: url)?.path else { return "<p>No kT results available</p>" }
            
            NSFileManager.defaultManager().createFileAtPath(newPath, contents: nil, attributes: nil)
            
            do {
                try csvData.writeToFile(newPath, atomically: true, encoding: NSUTF8StringEncoding)
                string += "<p>CSV data file available at \(newPath)</p>"
            } catch let error as NSError {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
            
        }
        
        return string
    }
    
    private class func createFooter() -> String {
        var string = "</body>\n"
        string += "</html>"
        
        return string
    }
}
