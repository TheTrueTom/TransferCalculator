# The transfer calculator [![GitHub license](https://img.shields.io/dub/l/vibe-d.svg)](https://raw.githubusercontent.com/TheTrueTom/TransferCalculator/master/LICENCE) [![GitHub release](https://img.shields.io/github/release/TheTrueTom/TransferCalculator.svg)](https://github.com/TheTrueTom/TransferCalculator/releases/latest)

## Description

Generates particles with randomly placed donor and/or acceptor luminescent dye, calculated the average distances between a dye and its closest acceptors/donors. Generates data in CSV file format for the kT transfer efficiency relative to the distance between donors and acceptors.

## Features

- Direct visualization of the current particle
- Responsive progress indicator
- A cancel button
- Less UI blockage
- Better multi-threading
- A batch calculation processor: list all the particles parameters you want to test and it will generate a report and the data that goes with it!

## Known issues

- UI can get unresponsive under certain conditions
- When stopping a list of jobs in batch mode, the current job is not cancelled, only the following jobs are.
- When doing more than a 1000 repeats the UI can get delayed, actual progress can be infered from the report which is updated after every job
- 
## Licence

The Transfer Calculator is released under the [MIT License](LICENSE.md).
