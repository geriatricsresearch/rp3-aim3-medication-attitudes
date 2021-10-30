* Edie Espejo
* Matthew Growdon
* 2021-10-28
* 2021-10-28

use "../data/step-2/cleaned-data.dta"

* Survey set command
svyset w6varunit [pweight=w6anfinwgt0], strata(w6varstrat)

svy, subpop(subpop): tab binaryattitude3
svy, subpop(subpop): tab binaryattitude4
svy, subpop(subpop): tab pillsmax


* Make the subpop changes
replace subpop=0 if binaryattitude3==. & binaryattitude4==. & pillsmax==.
svy, subpop(subpop): tab binaryattitude3
svy, subpop(subpop): tab binaryattitude4
svy, subpop(subpop): tab pillsmax


* For the Venn diagram folks
replace subpop=0 if binaryattitude3==.
replace subpop=0 if binaryattitude4==.
replace subpop=0 if pillsmax==.
svy, subpop(subpop): tab binaryattitude3
svy, subpop(subpop): tab binaryattitude4
svy, subpop(subpop): tab pillsmax
