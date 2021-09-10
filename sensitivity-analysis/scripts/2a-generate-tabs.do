* Script Setup -------------------------------------------- *
*
* | Author    | Edie Espejo
* | Study     | RP3 Aim 3 (Matthew Growdon)
* | Created   | x
* | Last Edit | x
* | Objective | Clean data for tables

cd "/Users/ee/GitHub/rp3-aim3-medication-attitudes/sensitivity-analysis"
use "data/step-1-self/cleaned-data.dta"


* Survey set command
svyset w6varunit [pweight=w6anfinwgt0], strata(w6varstrat)


* Variables
global table1vars age sex race educ medicaid marital regularmeds chronic health dementia proxy hospitalized doctor adls medicationsiadl diagnosis fall

global table1outcomes pillsmax binaryattitude3 binaryattitude4



* Table 1 Loop
mkdir "tables/table1"



foreach v of varlist $table1vars {
	
	tabout `v' if subpop using "tables/table1/`v'-raw.csv", cells(freq col) format(2) replace
	
	tabout `v' if subpop using "tables/table1/`v'-svy.csv", svy cells(freq) format(0) replace
	
	tabout `v' if subpop using "tables/table1/`v'-svy2.csv", svy cells(col) format(4) replace
	
}




* Table 2 Loop
mkdir "tables/table2"

foreach w of varlist $table1outcomes {
	mkdir "tables/table2/`w'"
}


foreach w of varlist $table1outcomes {
	
	foreach v of varlist $table1vars {
	
		tabout `v' `w' if subpop using "tables/table2/`w'/`v'-raw.csv", cells(freq) format(0) replace
		
		tabout `v' `w' if subpop using "tables/table2/`w'/`v'-svy.csv", svy cells(row) format(4) replace
	
	}
	
}
