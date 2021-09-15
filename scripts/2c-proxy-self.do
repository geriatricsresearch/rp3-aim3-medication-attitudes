* Script Setup -------------------------------------------- *
*
* | Author    | Edie Espejo
* | Study     | RP3 Aim 3 (Matthew Growdon)
* | Created   | 2021-04-01
* | Last Edit | 2021-09-15
* | Objective | Create tabs for Tables 1 and 2

cd "/Users/ee/GitHub/rp3-aim3-medication-attitudes/scripts"
use "../data/step-2/cleaned-data.dta"

replace subpop=0 if binaryattitude3==. & binaryattitude4==. & pillsmax==.

* Survey set command
svyset w6varunit [pweight=w6anfinwgt0], strata(w6varstrat)


* Variables
global table1vars age sex race educ medicaid marital regularmeds chronic health dementia hospitalized doctor adls medicationsiadl diagnosis fall

global table1outcomes pillsmax binaryattitude3 binaryattitude4

gen self_only=0
replace self_only=1 if subpop==1 & proxy==0

gen proxy_only=0
replace proxy_only=1 if subpop==1 & proxy==1


* Table 1 Loop (Self Only)
mkdir "../tables/table1-self"


foreach v of varlist $table1vars {
	
	tabout `v' if self_only using "../tables/table1-self/`v'-raw.csv", cells(freq col) format(2) replace
	
	tabout `v' if self_only using "../tables/table1-self/`v'-svy.csv", svy cells(freq) format(0) replace
	
	tabout `v' if self_only using "../tables/table1-self/`v'-svy2.csv", svy cells(col) format(4) replace
	
}


* Table 1 Loop (Proxy Only)
mkdir "../tables/table1-proxy"


foreach v of varlist $table1vars {
	
	tabout `v' if proxy_only using "../tables/table1-proxy/`v'-raw.csv", cells(freq col) format(2) replace
	
	tabout `v' if proxy_only using "../tables/table1-proxy/`v'-svy.csv", svy cells(freq) format(0) replace
	
	tabout `v' if proxy_only using "../tables/table1-proxy/`v'-svy2.csv", svy cells(col) format(4) replace
	
}
