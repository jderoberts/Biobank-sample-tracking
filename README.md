Examples of work from haematology research biobank at University of Cambridge.

# FluidX scan converter
Simple Perl script with GUI for converting output from FluidX multi-tube barcode reader to format required for database upload.

![Scan converter screenshot](/docs/scan_converter.png)

## Motivation
2D barcoded tubes are useful for storing small volumes of biological material with a very low space footprint.  These small tubes have no room for a human-readable barcode label, however, so the built-in 2D barcode on the base of the tube must be promptly uploaded to the database to ensure samples can be identified.  
This perl tool converts .csv output from the plate barcode reader to .xls format for database upload, associating unique tube barcodes with sample entries.

## Practical use
GUI application used fortnightly by lab staff to associate biobank sample tube barcodes with associated database records.

## Learning outcomes
GUI programming - element layout
Tk in Perl

## Requirements
- Perl 5 for Windows (Strawberry or ActivePerl)
- Perl Tk module 

## Setup
`wperl.exe barcode_scan_converter.pl `

# Sample Timepoints

## Motivation
In cancer research, it is useful for a researcher to obtain DNA samples from both the tumour (to check for particular mutations) and from the rest of the body, as a baseline for comparison (constitutional material).  The type of material that is suitable for each differs between conditions.
This script queries the biobank database to report what material is available of each type for a given sample donor.

![Sample timepoints gif](/docs/sample_timepoints.gif)

## Practical use
Accelerated time from information request about patients meeting inclusion criteria to response.

## Learning outcomes
- Integrating Selectize javascript library with CGI perl for enhanced user experience
- Using SQLite via Perl and Python interfaces

## Requirements
- Perl 5
  - DBI SQLite
- Apache/nginx
- [Selectize.js](https://github.com/selectize/selectize.js)

## Acknowledgements
Tony Attwood - Iterator.pm and example DBI code for interfacing with MySQL
