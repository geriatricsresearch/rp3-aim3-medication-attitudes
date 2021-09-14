* Script Setup -------------------------------------------- *
*
* | Author    | Edie Espejo
* | Study     | RP3 Aim 3 (Matthew Growdon)
* | Created   | 2021-04-01
* | Last Edit | 2021-09-14
* | Objective | Create tabs for Tables 1 and 2

cd "/Users/ee/GitHub/rp3-aim3-medication-attitudes/scripts"
use "../data/step-2/cleaned-data.dta"

replace subpop=0 if binaryattitude3==. & binaryattitude4==. & pillsmax==.

* Survey set command
svyset w6varunit [pweight=w6anfinwgt0], strata(w6varstrat)


* Variables
global table1vars age sex race educ medicaid marital regularmeds chronic health dementia proxy hospitalized doctor adls medicationsiadl diagnosis fall

global table1outcomes pillsmax binaryattitude3 binaryattitude4



* Table 1 Loop
mkdir "../tables/table1"

*tabout `v' if subpop using "../tables/table1/`v'-raw.csv", cells(freq col) format(2) replace
*collect clear
*quietly collect e(V): tab age if subpop
*quietly collect _r_b: svy, subpop(subpop): tab age
*collect layout (colname) (result)




foreach v of varlist $table1vars {
	
	tabout `v' if subpop using "../tables/table1/`v'-raw.csv", cells(freq col) format(2) replace
	
	tabout `v' if subpop using "../tables/table1/`v'-svy.csv", svy cells(freq) format(0) replace
	
	tabout `v' if subpop using "../tables/table1/`v'-svy2.csv", svy cells(col) format(4) replace
	
}




* Table 2 Loop
mkdir "../tables/table2"

foreach w of varlist $table1outcomes {
	mkdir "../tables/table2/`w'"
}


foreach w of varlist $table1outcomes {
	
	foreach v of varlist $table1vars {
	
		tabout `v' `w' if subpop using "../tables/table2/`w'/`v'-raw.csv", cells(freq) format(0) replace
		
		tabout `v' `w' if subpop using "../tables/table2/`w'/`v'-svy.csv", svy cells(row) format(4) replace
	
	}
	
}
