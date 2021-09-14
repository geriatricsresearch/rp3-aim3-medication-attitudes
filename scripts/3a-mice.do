* Script Setup -------------------------------------------- *
*
* | Author    | Edie Espejo
* | Study     | RP3 Aim 3 (Matthew Growdon)
* | Created   | 2021-06-09
* | Last Edit | 2021-09-14
* | Objective | MICE



cd "/Users/ee/GitHub/rp3-aim3-medication-attitudes/scripts"




* 0. Data ---------------------------------------------------- *
use "../data/step-2/cleaned-data.dta"
replace subpop=0 if binaryattitude3==. & binaryattitude4==. & pillsmax==.

mi set mlong
mi svyset w6varunit [pweight=w6anfinwgt0], strata(w6varstrat)




* 0. Variable Lists -------------------------------------------- *
global table1vars age sex race educ marital medicaid chronic regularmeds health dementia diagnosis proxy hospitalized doctor adls medicationsiadl fall 

global table1outcomes pillsmax binaryattitude3 binaryattitude4

global factorvars i.age i.sex i.chronic i.proxy i.regularmeds i.dementia



* 0. Multiple Imputation --------------------------------------- *

mi register imputed dementia doctor fall health hospitalized race regularmeds medicaid medicationsiadl

mi impute chained (logit) fall hospitalized doctor regularmeds medicaid medicationsiadl (mlogit) health race dementia = age sex educ marital chronic proxy, noisily add(20) rseed (1)

mkdir "../data/step-3"
save "../data/step-3/imputed-data.dta", replace



* 0. Saving First Imputation ----------------------------------- *
* Analysis of the first imputation dataset exists under `scripts-other/`
mi extract 1
save "../data/step-3/imputation-1.dta", replace



* 0. Back to Imputation Data ----------------------------------- *
use "../data/step-3/imputed-data.dta"

global table1vars age sex race educ marital medicaid chronic regularmeds health dementia diagnosis proxy hospitalized doctor adls medicationsiadl fall 

global table1outcomes pillsmax binaryattitude3 binaryattitude4

global factorvars i.age i.sex i.chronic i.proxy i.regularmeds i.dementia



* 1. Odds Ratios ----------------------------------------------- *

mkdir "../tables/log-odds"



* ------------------------------------------------ 1A. Bivariate *
* For each of the outcomes, create an Excel file that contains
* the log odds for each variable using bivariate logistic regressions.

foreach w of varlist $table1outcomes {
	
	foreach v of varlist $table1vars {
		
		collect clear
		
		collect get _r_b _r_se _r_lb _r_ub: mi estimate, post or: svy, subpop(subpop): logistic `w' i.`v'
		
		collect layout (colname[i.`v'])  (result)
		
		collect export "../tables/log-odds/`w'.xlsx", sheet(`v'_1) modify
	}

}


* ------------------------------------------------- 1B. Adjusted *
* For each of the outcomes, create an Excel file that contains
* the log odds for each variable using adjusted logistic regressions.


foreach w of varlist $table1outcomes {
	
	foreach v of varlist $table1vars {
		
		collect clear
		
		collect get _r_b _r_se _r_lb _r_ub: mi estimate, post or: svy, subpop(subpop): logistic `w' i.`v' $factorvars
		
		collect layout (colname[i.`v'])  (result)
		
		collect export "../tables/log-odds/`w'.xlsx", sheet(`v'_2) modify
		
	}

}





* 2. MICE Adjusted Probabilities ------------------------------- *

mkdir "../tables/table2-mice"

* ---------------------------------------- 2A. Coefficients Only *

collect clear

foreach w of varlist $table1outcomes {
	
	* Create a new collection for the current outcome.
	collect create collection_`w'_adj
	
	
	* For each of the covariates, run binary regression.
	foreach v of varlist $table1vars {
		
		* Collect the results into the collection created above.
		mi estimate: svy, subpop(subpop): logistic `w' i.`v' $factorvars
		collect _r_b: mimrgns i.`v', subpop(subpop) post predict(xb)
		
	}

}


collect set collection_binaryattitude3_adj
collect layout (colname) (result)

collect set collection_binaryattitude4_adj
collect layout (colname) (result)

collect set collection_pillsmax_adj
collect layout (colname) (result)


collect export "../tables/table2-mice/mice-probabilities.xlsx", name(collection_binaryattitude3_adj) sheet(binaryattitude3_adj) modify
collect export "../tables/table2-mice/mice-probabilities.xlsx", name(collection_binaryattitude4_adj) sheet(binaryattitude4_adj) modify
collect export "../tables/table2-mice/mice-probabilities.xlsx", name(collection_pillsmax_adj) sheet(pillsmax_adj) modify






* ------------------------------ 2B. Coefficients + SE + LB + UB *
collect clear


foreach w of varlist $table1outcomes {
	
	* Create a new collection for the current outcome.
	collect create collection_`w'_se
	
	
	* For each of the covariates, run binary regression.
	foreach v of varlist $table1vars {
		
		* Collect the resluts into the collection created above.
		
		mi estimate: svy, subpop(subpop): logistic `w' i.`v' $factorvars
		collect _r_b _r_se _r_lb _r_ub: mimrgns i.`v', subpop(subpop) post predict(xb)
	}

}

collect set collection_binaryattitude3_se
collect style row split, dups(repeat)
collect layout (colname) (result)

collect set collection_binaryattitude4_se
collect style row split, dups(repeat)
collect layout (colname) (result)

collect set collection_pillsmax_se
collect style row split, dups(repeat)
collect layout (colname) (result)

collect export "../tables/table2-mice/mice-prob-se.xlsx", name(collection_binaryattitude3_se) sheet(binaryattitude3_se) modify
collect export "../tables/table2-mice/mice-prob-se.xlsx", name(collection_binaryattitude4_se) sheet(binaryattitude4_se) modify
collect export "../tables/table2-mice/mice-prob-se.xlsx", name(collection_pillsmax_se) sheet(pillsmax_se) modify




* ------------------------------------------------- 2C. P-values *


foreach w of varlist $table1outcomes {
	mkdir "../tables/table2-mice/`w'"
}


foreach w of varlist $table1outcomes {
	
	* For each of the covariates, run binary regression.
	foreach v of varlist $table1vars {
		
		* Collect the results into the collection created above.
		
		mi estimate, post: svy, subpop(subpop): logistic `w' i.`v' $factorvars
		
		* 3 - Save p-value.
		testparm i.`v'
		local this_pvalue=r(p)
		
		file open myfile using "../tables/table2-mice/`w'/`v'-mice-adj-pvalue.txt", write replace
		file write myfile `"`this_pvalue'"'
		file close myfile
		

	}

}






* 3. MICE Adjusted Probabilities (Bivariate) ------------------- *


* ------------------------------ 3A. Coefficients + SE + LB + UB *
collect clear


foreach w of varlist $table1outcomes {
	
	* Create a new collection for the current outcome.
	collect create collection_`w'_se
	
	
	* For each of the covariates, run binary regression.
	foreach v of varlist $table1vars {
		
		* Collect the resluts into the collection created above.
		
		mi estimate: svy, subpop(subpop): logistic `w' i.`v'
		collect _r_b _r_se _r_lb _r_ub: mimrgns i.`v', subpop(subpop) post predict(xb)
	}

}

collect set collection_binaryattitude3_se
collect style row split, dups(repeat)
collect layout (colname) (result)

collect set collection_binaryattitude4_se
collect style row split, dups(repeat)
collect layout (colname) (result)

collect set collection_pillsmax_se
collect style row split, dups(repeat)
collect layout (colname) (result)

collect export "../tables/table2-mice/bivariate-prob-se.xlsx", name(collection_binaryattitude3_se) sheet(binaryattitude3_se) modify
collect export "../tables/table2-mice/bivariate-prob-se.xlsx", name(collection_binaryattitude4_se) sheet(binaryattitude4_se) modify
collect export "../tables/table2-mice/bivariate-prob-se.xlsx", name(collection_pillsmax_se) sheet(pillsmax_se) modify


* ------------------------------------------------- 3C. P-values *


foreach w of varlist $table1outcomes {
	mkdir "../tables/table2-mice/`w'-bivariate"
}


foreach w of varlist $table1outcomes {
	
	* For each of the covariates, run binary regression.
	foreach v of varlist $table1vars {
		
		* Collect the results into the collection created above.
		
		mi estimate, post: svy, subpop(subpop): logistic `w' i.`v'
		
		* 3 - Save p-value.
		testparm i.`v'
		local this_pvalue=r(p)
		
		file open myfile using "../tables/table2-mice/`w'-bivariate/`v'-mice-adj-pvalue.txt", write replace
		file write myfile `"`this_pvalue'"'
		file close myfile
		

	}

}
