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
    
    init(jobList: [Job], distanceResults: [DistancesResult], kTResults: [[(distance: Double, kT: Double)]]) {
        
    }
    
    func createHeader() -> String {
        var string = "<!DOCTYPE html>\n"
        string += "<html lang='en'>\n"
        string += "<head>\n"
        string += "<title>Result Summary</title>\n"
        string += "</head>\n"
        string += "<body>\n"
        
        return string
    }
    
    func createExperiment(job: Job) -> String {
        var string = "<h1>\(job.description)</h1>"
        string += "<h2>Parameters</h2>"
        
        string += "<h2>Distances</h2>"
        
        string += "<h2>kT</h2>"
        
        return string
    }
}