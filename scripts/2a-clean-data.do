* ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * 
* Script Setup -------------------------------------------- *
*
* | Author    | Edie Espejo
* | Study     | RP3 Aim 3 (Matthew Growdon)
* | Created   | 2021-05-04
* | Last Edit | 2021-05-25
* | Objective | Clean data for table 3


*----------------------------------------*
* Data ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ *
cd "/Users/ee/GitHub/rp3-aim3-medication-attitudes/scripts"
use "../data/step-1/nhats-ma-module.dta"



*----------------------------------------*
* Survey * ~ * ~ * ~ * ~ * ~ * ~ * ~ * ~ *
svyset w6varunit [pweight=w6anfinwgt0], strata(w6varstrat)



*----------------------------------------*
* Label Variables  ~ * ~ * ~ * ~ * ~ * ~ *
label variable ma6attitude3 "take more meds than needed"
label variable ma6attitude4 "willing to stop take meds"
label variable ma6pillsmax "max number of pills comfortable to take"


label variable r6d2intvrage "categorical age at interview"
label define r6d2intvrage_lab 1 "65 to 69" 2 "70 to 74" 3 "75 to 79" 4 "80 to 84" 5 "85 to 89" 6 "90+"
label values r6d2intvrage r6d2intvrage_lab

label variable r5dgender "gender"
label define r5dgender_lab 1 "male" 2 "female"
label values r5dgender r5dgender_lab




*----------------------------------------*
* Mutate Variables ~ * ~ * ~ * ~ * ~ * ~ *

* Outcome 1 ---------- Binary Attitude 3 *
gen binaryattitude3=.
replace binaryattitude3=1 if ma6attitude3==1 | ma6attitude3==2
replace binaryattitude3=0 if ma6attitude3==3 | ma6attitude3==4
label variable binaryattitude3 "binary, take more meds than needed"
label define binaryattitude3_lab 0 "disagree" 1 "agree"
label values binaryattitude3 binaryattitude3_lab


* Outcome 2 ---------- Binary Attitude 4 *
gen binaryattitude4=.
replace binaryattitude4=1 if ma6attitude4==1 | ma6attitude4==2
replace binaryattitude4=0 if ma6attitude4==3 | ma6attitude4==4
label variable binaryattitude4 "binary, willing to stop take meds"
label define binaryattitude4_lab 0 "disagree" 1 "agree"
label values binaryattitude4 binaryattitude4_lab


* Outcome 3 ------------------ Pills Max *
gen pillsmax=.
replace pillsmax=1 if ma6pillsmax==1
replace pillsmax=0 if ma6pillsmax==2 | ma6pillsmax==3 | ma6pillsmax==4 | ma6pillsmax==5 | ma6pillsmax==6
label variable pillsmax "uncomfortable taking 5 or more pills"
label define pillsmax_lab 0 "disagree" 1 "agree"
label values pillsmax pillsmax_lab


* Covariate 1 --------------------- Age *
gen age=.
replace age=1 if r6d2intvrage==1 | r6d2intvrage==2
replace age=2 if r6d2intvrage==3 | r6d2intvrage==4
replace age=3 if r6d2intvrage==5 | r6d2intvrage==6
label variable age "categorical age at interview, 3 categories"
label define age_lab 1 "65 to 74" 2 "75 to 84" 3 "85 +"
label values age age_lab


* Covariate 2 --------------------- Sex *
*    Using the `r5dgender` variable.
gen sex=r5dgender
label variable sex "biological sex"
label define sex_lab 1 "male" 2 "female"
label values sex sex_lab


* Covariate 3 -------------------- Race *
gen race=.
replace race=1 if rl5dracehisp==1
replace race=2 if rl5dracehisp==2
replace race=3 if rl5dracehisp==4
replace race=4 if rl5dracehisp==3 | rl5dracehisp==5
label variable race "race"
label define race_lab 1 "white, non-hispanic" 2 "black, non-hispanic" 3 "hispanic" 4 "other"
label values race race_lab

* Covariate 4 --------------- Education *
gen educ=.
replace educ=1 if education<4
replace educ=2 if education==4
replace educ=3 if education>=5
label variable educ "education"
label define educ_lab 1 "below high school" 2 "high school" 3 "beyond high school"
label values educ educ_lab

* Covariate 5 ---------------- Medicaid *

* Medicaid Coverage A
* Not exactly sure what this variable should be. I'm using fq6primpayer.
* gen medicaid0=.
* replace medicaid0=1 if fq6primpayer==3
* replace medicaid0=0 if fq6primpayer==1 | fq6primpayer==2 | fq6primpayer==4 | fq6primpayer==5
* label variable medicaid0 "whether primary payer for care is medicaid or not"
label define medicaid_lab 1 "has medicaid" 0 "does not have medicaid"
* label values medicaid0 medicaid_lab


*  Medicaid Coverage B
*     Trying the other variable to see if it works better.
gen medicaid=.
replace medicaid=1 if ip6cmedicaid==1
replace medicaid=0 if ip6cmedicaid==2
label variable medicaid "whether primary payer for care is medicaid or not"
label values medicaid medicaid_lab



* Covariate 6 ---------- Marital Status *
gen marital=.
replace marital=1 if hh6dmarstat==1 | hh6dmarstat==2
replace marital=2 if hh6dmarstat>=3
label variable marital "marital status"
label define marital_lab 1 "married or living with partner" 2 "separated, divorced, widowed, never married"
label values marital marital_lab


* Covariate 7 ------------ Regular Meds *
gen regularmeds=.
replace regularmeds=0 if ma6medsnum==0 | ma6medsnum==1 | ma6medsnum==2
replace regularmeds=1 if ma6medsnum>=3
label variable regularmeds "number of regular medications"
label define regularmeds_lab2 0 "less than 6" 1 "6 or more"
label values regularmeds regularmeds_lab2


* Covariate 8 --------- Chronic Disease *
global diseases hc6disescn1-hc6disescn10
foreach w of varlist $diseases {
	replace `w'=1 if `w'==7
	replace `w'=0 if `w'==2 | `w'<0
}

egen chronic0 = rowtotal(hc6disescn1 hc6disescn2 hc6disescn3 hc6disescn4 hc6disescn5 hc6disescn6 hc6disescn7 hc6disescn8 hc6disescn10), missing

gen chronic=.
replace chronic=1 if chronic0==0 | chronic0==1
replace chronic=2 if chronic0==2 | chronic0==3
replace chronic=3 if chronic0>3
label variable chronic "number of chronic conditions, categorical"
label define chronic_lab 1 "0-1" 2 "2-3" 3 ">3"
label values chronic chronic_lab


* Covariate 9 ------------- Self Health *
gen health=.
replace health=1 if hc6health==1 | hc6health==2
replace health=2 if hc6health==3
replace health=3 if hc6health==4 | hc6health==5

label variable health "self-rated health"
label define health_lab 1 "excellent/very good" 2 "good" 3 "fair/poor"
label values health health_lab


* Covariate 9 ---------------- Dementia *
gen dementia=.
replace dementia=2 if r6demclas==1
replace dementia=1 if r6demclas==2
* replace dementia=0 if r6demclas==3
label variable dementia "dementia status"
label define dementia_lab 2 "probable dementia" 1 "possible dementia" 0 "no dementia"
label values dementia dementia_lab


* Subpop Variable ---------------------- *
gen subpop=0
replace subpop=1 if dementia==1 | dementia==2
label variable subpop "probable/possible dementia subpopulation"
label define subpop_lab 0 "not in sample" 1 "in sample"
label values subpop subpop_lab



* Covariate 10 ----------- Proxy Status *
gen proxy=.
replace proxy=0 if is6resptype==1
replace proxy=1 if is6resptype==2
label variable proxy "proxy status"
label define proxy_lab 0 "sample person" 1 "proxy respondent"
label values proxy proxy_lab

* Covariate 11 ----------- Hospitalized *
gen hospitalized=.
replace hospitalized=1 if hc6hosptstay==1
replace hospitalized=0 if hc6hosptstay==2
label variable hospitalized "hospitalized within last year"
label define hospitalized_lab 1 "hospitalized" 0 "not hospitalized"
label values hospitalized hospitalized_lab

* Covariate 12 --------- Regular Doctor *
gen doctor=.
replace doctor=1 if mc6regdoclyr==1
replace doctor=0 if mc6regdoclyr==2
label variable doctor "seen regular doctor within last year"
label define doctor_lab 1 "seen doctor" 0 "did not see doctor"
label values doctor doctor_lab


* Covariate 13 ------- Medications IADL *
gen medicationsiadl=.
replace medicationsiadl=0 if mc6dmedssfdf==2
replace medicationsiadl=1 if mc6dmedssfdf==1 | mc6dmedssfdf==3
*  replace medicationsiadl=1 if mc6dmedssfdf==1 | mc6dmedssfdf==3 | mc6dmedssfdf==4 | mc6dmedssfdf==8 | mc6dmedssfdf==9
label variable medicationsiadl "difficulty tracking medications"
label define medicationsiadl_lab 0 "no difficulty" 1 "difficulty"
label values medicationsiadl medicationsiadl_lab


* Covariate 14 --- <=2 ADL Dependencies *

*      Eating
gen eatdep=.
replace eatdep=0 if sc6deatsfdf==2
replace eatdep=0 if (sc6deatsfdf==1|sc6deatsfdf==3) & (sc6deathelp==-1|sc6deathelp==1)
replace eatdep=1 if (sc6deatsfdf==1|sc6deatsfdf==3) & (sc6deathelp==2|sc6deathelp==8)

*      Bathing
gen bathdep=.
replace bathdep=0 if sc6dbathsfdf==2
replace bathdep=0 if (sc6dbathsfdf==3 | sc6dbathsfdf==1) & (sc6dbathhelp==-1|sc6dbathhelp==1)
replace bathdep=1 if (sc6dbathsfdf==3 | sc6dbathsfdf==1) & (sc6dbathhelp==2|sc6dbathhelp==8)

*      Toileting
gen toiletdep=.
replace toiletdep=0 if sc6dtoilsfdf==2
replace toiletdep=0 if (sc6dtoilsfdf==3 | sc6dtoilsfdf==1) & (sc6dtoilhelp==-1|sc6dtoilhelp==1)
replace toiletdep=1 if (sc6dtoilsfdf==3 | sc6dtoilsfdf==1) & (sc6dtoilhelp==2|sc6dtoilhelp==8)

*      Dressing
gen dressdep=.
replace dressdep=0 if sc6ddressfdf==2
replace dressdep=0 if (sc6ddressfdf==3 | sc6ddressfdf==1) & (sc6ddreshelp==-1|sc6ddreshelp==1)
replace dressdep=1 if (sc6ddressfdf==3 | sc6ddressfdf==1) & (sc6ddreshelp==2|sc6ddreshelp==8)


*      Bed
gen beddep=.
replace beddep=0 if mo6dbedsfdf==2
replace beddep=0 if (mo6dbedsfdf==3 | mo6dbedsfdf==1) & (mo6dbedhelp==-1|mo6dbedhelp==1)
replace beddep=1 if (mo6dbedsfdf==3 | mo6dbedsfdf==1) & (mo6dbedhelp==2|mo6dbedhelp==8)

*      Sum
egen adls0 = rowtotal(eatdep bathdep toiletdep dressdep beddep), missing 

gen adls=.
replace adls=1 if adls0==2 | adls0==3 | adls0==4 | adls0==5
replace adls=0 if adls0==0 | adls0==1
label variable adls "number of adl dependencies >=2"
label define adls_lab 1 ">=2" 0 "<2"
label values adls adls_lab


* Covariate 15 ------------- Fall Month *
gen fall=.
replace fall=1 if hc6fllsinmth==1
replace fall=0 if hc6fllsinmth==2
label variable fall "fall in last month"
label define fall_lab 1 "fallen" 0 "no falls"
label values fall fall_lab


* Covariate 16 ---------------- Surgery *
gen hipkneesurgery=.
replace hipkneesurgery=0 if hc6knesrgyr==2 & hc6hipsrgyr==2
replace hipkneesurgery=1 if hc6knesrgyr==1 | hc6hipsrgyr==1
label variable hipkneesurgery "hip or knee surgery within last year"
label define hipkneesurgery_lab 1 "had hip or knee surgery" 0 "no surgery"
label values hipkneesurgery hipkneesurgery_lab

* Covariate 17 ---------------- Dementia Diagnosis *
gen diagnosis=.
replace diagnosis=1 if hc6disescn9==1 | hc6disescn9==7
replace diagnosis=0 if hc6disescn9==0
label variable diagnosis "dementia diagnosis"
label define diagnosis_lab 0 "no dementia diagnosis" 1 "dementia diagnosed"
label values diagnosis diagnosis_lab


replace subpop=0 if binaryattitude3==. & binaryattitude4==. & pillsmax==.

mkdir "../data/step-2"
save "../data/step-2/cleaned-data.dta", replace

