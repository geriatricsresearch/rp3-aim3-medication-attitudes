# Project Details

**Project**                 Attitudes Toward Deprescribing among Older Adults with Dementia in the US  
**Principal Investigator**  Matthew Growdon                
**Statistician**            Edie Espejo                    
**Collaborators**           Bocheng Jing, John Boscardin, Andrew Zullo, Kristine Yaffe, Kenneth Boockvar, Michael Steinman  
**Data**                    NHATS Round 6, public-use data    
**Publications**            *What shall I put here if this is in progress?*                           
**Project Start**           2021-01-14                     
**Software**                STATA, R, Python 3, Jupyter Notebook

# Goal
This aim explores attitudes of community-dwelling older adults with dementia and their caregivers' attitude toward medications and their willingness to deprescribe. This project focuses on 3 different outcomes variables:

- Belief of taking 1+ medications that are no longer needed
- Willingness to deprescribe if a doctor says it's possible
- Comfort with taking 5+ pills daily

These outcome variables were based on *insert information here*.

# Step 1. Raw Data.
Cohort eligibility requirements were having a completed NHATS Round 6 MA module and were aged 65 or older in that year. We merged these data with the NHATS dementia classifcations data and NHATS Early Life files from Rounds 1 and 5. The scripts used to do this are saved under the `/scripts` folder as `1a-nhats-dementia-class.do` and `1b-process-sample.R`.

# Step 2. Clean Data & Generate Tabs.
In the next step, the data are manually labelled in `2a-clean-data.do`. Then, we use STATA to produce raw and survey-weighted tables for Table 1 (`2b-generate-tabs.do`). A supplementary table stratifies Table 1 by proxy status (`2c-proxy-self.do`). Using the files output by 2B, `2c-table-one.R` is a script that compiles Table 1 and the supplementary stratified by proxy status table.

# Step 3. MICE & Logistic Models.
The `3a-mice.do` STATA file specifies the imputation of missing data using chained equations. Output data (MICE marginal probabilities of outcomes) are Excel files which are cleaned up by `3b-table-two.R` into our formal Table 2. For references, the corresponding odds ratios are estimated in `3c-odds-ratios.R`.

# Step 4. Visualization.
We create the following figure based on the probabilities generated in the previous step using `4a-outcome-plot.R`.

![attitude-agreements 002](https://user-images.githubusercontent.com/20163246/133846039-9f9444b2-e6d8-48fe-a148-206ed2adb3ed.jpeg)


The 3-way Venn Diagram was created using STATA in Jupyter Notebook (Python) in `4b-venn-diagrams.ipynb`.

![venn-3way-svy](https://user-images.githubusercontent.com/20163246/133846058-4aa7c9eb-931b-4612-aca0-e825019336b0.png)


The script `4c-dementia-pills.ipynb` is not a visualization script, but grounds some information needed to understand the distribution of how many regular medications patients with and without dementia are taking.
