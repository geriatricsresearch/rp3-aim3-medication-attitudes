* This is the code from 'NHATS Dementia Classification Addendum for Follow-up Rounds.pdf'
* Stata programming statements for Round 2
* Subsequent rounds can be programmed by replacing all round 2 variables with the appropriate round

cd "/Users/ee/GitHub/rp3-aim3-medication-attitudes/scripts"
use "../data/nhats/NHATS_Round_6_SP_File_V2.dta"


** NOTE: The input file to run this code is the NHATS_Round_2_SP_File**


*SET MISSING (RESIDENTIAL CARE FQ ONLY) AND N.A. (NURSING HOME RESIDENTS, DECEASED)*
gen r6demclas=-9 if r6dresid==3 | r6dresid==5 | r6dresid==7
replace r6demclas=-1 if r6dresid==6 |r6dresid==8
*CODE PROBABLE IF DEMENTIA DIAGNOSIS REPORTED BY SELF OR PROXY*
replace r6demclas=1 if (hc6disescn9==1 | hc6disescn9==7) & (is6resptype==1 | is6resptype==2)
tab r6demclas

*CODE AD8_SCORE*
*INITIALIZE COUNTS TO NOT APPLICABLE*
*ASSIGN VALUES TO AD8 ITEMS IF PROXY AND DEMENTIA CLASS NOT ALREADY ASSIGNED BY REPORTED DIAGNOSIS
foreach num of numlist 1/8 {
  *INITIALIZE COUNTS TO NOT APPLICABLE*
  gen r6ad8_`num'=-1
  replace r6ad8_`num'=. if is6resptype==2 & r6demclas==.
  *PROXY REPORTS A CHANGE OR ALZ/DEMENTIA*
  replace r6ad8_`num'=1 if is6resptype==2 & r6demclas==. & (cp6chgthink`num'==1 | cp6chgthink`num'==3)
  *PROXY REPORTS NO CHANGE*
  replace r6ad8_`num'=0 if is6resptype==2 & r6demclas==. & (cp6chgthink`num'==2) & r6ad8_`num'==.
}

foreach num of numlist 1/8 {
  *INITIALIZE COUNTS TO NOT APPLICABLE*
  gen r6ad8miss_`num'=-1
  replace r6ad8miss_`num'=0 if is6resptype==2 & r6demclas==. & (r6ad8_`num'==0 | r6ad8_`num'==1)
  replace r6ad8miss_`num'=1 if is6resptype==2 & r6demclas==. & r6ad8_`num'==.
  replace r6ad8_`num'=0 if is6resptype==2 & r6demclas==. & r6ad8_`num'==.
}

*COUNT AD8 ITEMS*
gen r6ad8_score=-1
replace r6ad8_score=(r6ad8_1+r6ad8_2+r6ad8_3+r6ad8_4+r6ad8_5+r6ad8_6+r6ad8_7+r6ad8_8) if is6resptype==2 & r6demclas==.

*SET PREVIOUS ROUND DEMENTIA DIAGNOSIS BASED ON AD8 TO AD8_SCORE=8*
replace r6ad8_score=8 if cp6dad8dem==1 & is6resptype==2 & r6demclas==.

*COUNT MISSING AD8 ITEMS*
gen r6ad8_miss= -1
replace r6ad8_miss=(r6ad8miss_1+r6ad8miss_2+r6ad8miss_3+r6ad8miss_4+r6ad8miss_5+r6ad8miss_6+r6ad8miss_7+r6ad8miss_8) if is6resptype==2 & r6demclas==.

*CODE AD8 DEMENTIA CLASS*
*IF SCORE>=2 THEN MEETS AD8 CRITERIA*
gen r6ad8_dem=1 if r6ad8_score>=2

* IF SCORE IS 0 OR 1 OR ALL ITEMS MISSING THEN DOES NOT MEET AD8 CRITERION*
replace r6ad8_dem=2 if (r6ad8_score==0 | r6ad8_score==1 | r6ad8_miss==8) & r6ad8_dem==.
*UPDATE DEMENTIA CLASSIFICATION VARIABLE WITH AD8 CLASS*
*PROBABLE DEMENTIA BASED ON AD8 SCORE*
replace r6demclas=1 if r6ad8_dem==1 & r6demclas==.
*NO DIAGNOSIS, DOES NOT MEET AD8 CRITERION, AND PROXY SAYS CANNOT ASK SP COGNITIVE ITEMS*
replace r6demclas=3 if r6ad8_dem==2 & cg6speaktosp==2 & r6demclas==.
*tab r6demclas

*CODE DATE ITEMS AND COUNT*
*USE THE FOLLOWING LOOP FOR ROUNDS 1-3, 5 and forward*
foreach num of numlist 1/4 {
  *CODE ONLY YES/NO RESPONSES: MISSING/NA CODES -1, -9 LEFT MISSING*
  gen r6date_item`num'=cg6todaydat`num' if cg6todaydat`num'>0
  *2: NO/DK OR -7: REFUSED RECODED TO : NO/DK/RF*
  replace r6date_item`num'=0 if cg6todaydat`num'==2 | cg6todaydat`num'==-7
}


*COUNT CORRECT DATE ITEMS*
gen r6date_sum=r6date_item1 + r6date_item2 + r6date_item3 + r6date_item4
* USE THIS LINE FOR ROUNDS 1-3, 5 and forward

*PROXY SAYS CAN'T SPEAK TO SP*
replace r6date_sum=-2 if r6date_sum==. & cg6speaktosp==2
*PROXY SAYS CAN SPEAK TO SP BUT SP UNABLE TO ANSWER*
replace r6date_sum=-3 if (r6date_item1==. | r6date_item2==. | r6date_item3==. | r6date_item4==.) & cg6speaktosp==1
gen r6date_sumr=r6date_sum
*MISSING IF PROXY SAYS CAN'T SPEAK TO SP*
replace r6date_sumr=. if r6date_sum==-2
*0 IF SP UNABLE TO ANSWER*
replace r6date_sumr=0 if r6date_sum==-3



*PRESIDENT AND VICE PRESIDENT NAME ITEMS AND COUNT*
** CODE ONLY YES/NO RESPONSES: MISSING/N.A. CODES -1,-9 LEFT MISSING *
*2:NO/DK OR -7: REFUSED RECODED TO 0:NO/DK/RF*
gen r6preslast=cg6presidna1 if cg6presidna1>0
replace r6preslast=0 if cg6presidna1==-7 | cg6presidna1==2
gen r6presfirst=cg6presidna3 if cg6presidna3>0
replace r6presfirst=0 if cg6presidna3==-7 | cg6presidna3==2
gen r6vplast=cg6vpname1 if cg6vpname1>0
replace r6vplast=0 if cg6vpname1==-7 | cg6vpname1==2
gen r6vpfirst=cg6vpname3 if cg6vpname3>0
replace r6vpfirst=0 if cg6vpname3==-7 | cg6vpname3==2

*COUNT CORRECT PRESIDENT/VP NAME ITEMS*
gen r6presvp= r6preslast+r6presfirst+r6vplast+r6vpfirst
** PROXY SAYS CAN'T SPEAK TO SP *
replace r6presvp=-2 if r6presvp==. & cg6speaktosp==2
** PROXY SAYS CAN SPEAK TO SP BUT SP UNABLE TO ANSWER *
replace r6presvp=-3 if r6presvp==. & cg6speaktosp==1 & (r6preslast==. | r6presfirst==. | r6vplast==. | r6vpfirst==.)

gen r6presvpr=r6presvp
*MISSING IF PROXY SAYS CAN’T SPEAK TO SP*
replace r6presvpr=. if r6presvp==-2
*0 IF SP UNABLE TO ANSWER*
replace r6presvpr=0 if r6presvp==-3
*ORIENTATION DOMAIN: SUM OF DATE RECALL AND PRESIDENT/VP NAMING*
gen r6date_prvp=r6date_sumr + r6presvpr


*EXECUTIVE FUNCTION DOMAIN: CLOCK DRAWING SCORE*
gen r6clock_scorer=cg6dclkdraw
replace r6clock_scorer=. if cg6dclkdraw==-2 | cg6dclkdraw==-9
replace r6clock_scorer=0 if cg6dclkdraw==-3 | cg6dclkdraw==-4 | cg6dclkdraw==-7

*IMPUTE MEAN SCORE TO PERSONS MISSING A CLOCK*
*IF PROXY SAID CAN ASK SP*
replace r6clock_scorer=2 if cg6dclkdraw==-9 & cg6speaktosp==1
*IF SELF-RESPONDENT*
replace r6clock_scorer=3 if cg6dclkdraw==-9 & cg6speaktosp==-1


*MEMORY DOMAIN: IMMEDIATE AND DELAYED WORD RECALL*
gen r6irecall=cg6dwrdimmrc
replace r6irecall=. if cg6dwrdimmrc==-2 | cg6dwrdimmrc==-1
replace r6irecall=0 if cg6dwrdimmrc==-7 | cg6dwrdimmrc==-3


gen r6drecall=cg6dwrddlyrc
replace r6drecall=. if cg6dwrddlyrc==-2 | cg6dwrddlyrc==-1
replace r6drecall=0 if cg6dwrddlyrc==-7 | cg6dwrddlyrc==-3


gen r6wordrecall0_20=r6irecall+r6drecall
*CREATE COGNITIVE DOMAINS FOR ALL ELIGIBLE*
gen r6clock65=0 if r6clock_scorer>1 & r6clock_scorer<=5
replace r6clock65=1 if r6clock_scorer>=0 & r6clock_scorer<=1
gen r6word65=0 if r6wordrecall0_20>3 & r6wordrecall0_20<=20
replace r6word65=1 if r6wordrecall0_20>=0 & r6wordrecall0_20<=3
gen r6datena65=0 if r6date_prvp>3 & r6date_prvp<=8
replace r6datena65=1 if r6date_prvp>=0 & r6date_prvp<=3

*CREATE COGNITIVE DOMAIN SCORE*
gen r6domain65 = r6clock65+r6word65+r6datena65

*UPDATE COGNITIVE CLASSIFICATION*
*PROBABLE DEMENTIA*
replace r6demclas=1 if r6demclas==. & (cg6speaktosp==1 | cg6speaktosp==-1) & (r6domain65==2 | r6domain65==3)
*POSSIBLE DEMENTIA*
replace r6demclas=2 if r6demclas==. & (cg6speaktosp==1 | cg6speaktosp==-1) & r6domain65==1
*NO DEMENTIA*
replace r6demclas=3 if r6demclas==. & (cg6speaktosp==1 | cg6speaktosp==-1) & r6domain65==0

*Label variables and values*
label variable r6ad8_dem "Dementia classification based on proxy AD8 report"
label define r6ad8_dem_values 1 "1 Meets dementia criteria" 2 "2 Does not meet dementia criteria"
label values r6ad8_dem r6ad8_dem_values
label variable r6demclas "r6 NHATS Dementia Diagnosis 65+"
label define dementialabel652 1 "1 Probable dementia" 2 "2 Possible dementia" 3 "3 No dementia" -1 "-1 Deceased or nursing home resident in R1 and r6" -9 "-9 Missing"
label values r6demclas dementialabel652
label define domain_labels2 0 "0 Does not meet criteria" 1 "1 Meets criteria"
label values r6clock65 r6word65 r6datena65 domain_labels2
label define domain65_label2 0 "0 Not impaired" 1 "Impaired in 1 domain" 2 "Impaired in 2 domains" 3 "Impaired in 3 domains"
label values r6domain65 domain65_labels2
tab r6demclas

mkdir "../data/step-1"
save "../data/step-1/dementia-classified-nhats.dta", replace
