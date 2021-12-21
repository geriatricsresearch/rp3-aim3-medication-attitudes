# ------------------------------------------------------------------------
# Author: Edie Espejo
# Project: RP3 Aim 3 (Matthew Growdon)
# Date Created: 2021-07-30
# Last Edit:    2021-12-16
# Objective: Create Table 2 out of STATA output



# Libraries --------------------------------------------------------------
library(scales)
library(readxl)
library(dplyr)


# Read in folders/files --------------------------------------------------

tbl2_folders <- list.files('../tables/table2', full.names=TRUE)
tbl2_files   <- lapply(tbl2_folders, function(m) list.files(m, full.names=TRUE))

outcome_vars <- c('Believe Taking One or More Medication No Longer Needed',
                  'Willing To Deprescribe If Doctor Said Possible',
                  'Uncomfortable Taking 5 Or More Pills')

tbl2_order <- 'age sex race educ marital medicaid chronic regularmeds health dementia diagnosis proxy hospitalized doctor adls medicationsiadl fall'
tbl2_order <- strsplit(x=tbl2_order, split=' ')[[1]]





# Helper Functions --------------------------------------------------

invlogit <- function(k) exp(k) / (1 + exp(k))
rounded_percent <- function(m) paste0(round(m*100, 0), '%')

readOutputForTable2 <- function(m, stata_table, order_list, percents=FALSE) {
  this_row        <- nrow(stata_table)-1
  agree_col       <- as.numeric(which(apply(stata_table, 2, function(k) any(grepl('^agree', k)))))
  agree_decimals  <- as.numeric(stata_table[3:this_row, agree_col])
  
  if (percents) {
    agree_decimals  <- rounded_percent(agree_decimals)
    
  } else {
    total_col <- as.numeric(which(apply(stata_table, 2, function(k) any(grepl('^Total', k)))))
    total_col <- as.numeric(stata_table[3:this_row, tail(total_col, 1)])
    
    agree_decimals <- rounded_percent(agree_decimals / total_col)
  }
  
  agree_labels <- stata_table[,1][3:(2+length(agree_decimals))]
  
  clean_tab  <- cbind(agree_labels, agree_decimals)
  
  name_split <- strsplit(order_list[m], '')[[1]]
  name_upper <- paste0(toupper(name_split[1]), paste0(name_split[2:length(name_split)], collapse=''))
  sub_labels <- c(name_upper, '')
  clean_tab  <- data.frame(rbind(sub_labels, clean_tab))
  
  if (percents) {
    col_name <- 'Strongly Agree/Agree (%)'
  } else {
    col_name <- 'Strongly Agree/Agree (Unweighted)'
  }
  names(clean_tab) <- c('Characteristic',
                        col_name)
  
  row.names(clean_tab) <- 1:nrow(clean_tab)
  
  return(clean_tab)
}




readPvalues <- function(outcome_variable) {
  outcome_path <- paste0('../tables/table2-mice/', outcome_variable)
  
  short_name_files <- list.files(outcome_path)
  covariate_names <- gsub('-mice-adj-pvalue.txt', '', short_name_files)
  
  full_name_files <- list.files(outcome_path, full.names=TRUE)
  
  pvalue_data   <- lapply(1:length(full_name_files), function(k) scan(full_name_files[k]))
  
  names(pvalue_data) <- covariate_names
  
  table3_covariate_order <- c('age', 'sex', 'race', 'educ', 'medicaid', 'marital',
                              'regularmeds', 'chronic', 'health', 'dementia', 'diagnosis', 'proxy',
                              'hospitalized', 'doctor', 'adls', 'medicationsiadl',
                              'fall')
  
  table3_list <- lapply(table3_covariate_order, function(k) pvalue_data[[k]])
  
  pvalue_df <- data.frame(cbind(table3_covariate_order, do.call(rbind, table3_list)))
  names(pvalue_df) <- c('covariate', outcome_variable)
  
  return(pvalue_df)
}









# Clean Counts / Weighted Percentages  --------------------------------------------------s

# i <- 1
# m <- 3

# Look at an outcome variable subtable
all_outcomes <- lapply(1:length(tbl2_files), function(i) {
  
  this_subtbl <- tbl2_files[[i]]

  this_outcome_tbl <- lapply(1:length(tbl2_order), function(m) {
    # See which have to do with a characteristic variable
    these_files <- this_subtbl[which(grepl(pattern=paste0(tbl2_order[m],'-'), this_subtbl))]
    
    
    # 1. Raw Counts --------------------------------------------
    count_tab       <- read.delim(these_files[[1]])
    count_tab_clean <- readOutputForTable2(m, count_tab, tbl2_order, percents=FALSE)
    
    # 2. Survey-weighted Percentages ---------------------------
    svy_tab       <- read.delim(these_files[[2]])
    svy_tab_clean <- readOutputForTable2(m, svy_tab, tbl2_order, percents=TRUE)
    
    # 3. Put together ------------------------------------------
    # cbind(count_tab_clean %>% select(Characteristic, `Strongly Agree/Agree (Unweighted)`),
    #       svy_tab_clean %>% select(`Strongly Agree/Agree (%)`))
    
    revision_table <- count_tab
    revision_table <- revision_table[3:(nrow(count_tab)-1), c(1,3,4)]
    
    names(revision_table) <- c('Characteristic', 'a', 'd')
    revision_table <- left_join(revision_table,
                                count_tab_clean %>%
                                  rename(b=`Strongly Agree/Agree (Unweighted)`)) %>%
      
      left_join(svy_tab_clean) %>%
      mutate(`Strongly Agree/Agree (Unweighted)`=paste0(a, '/', d)) %>%
      select(Characteristic, `Strongly Agree/Agree (Unweighted)`, `Strongly Agree/Agree (%)`)
    
    return(revision_table)
    
  })
  
  do.call(rbind, this_outcome_tbl)

})

all_outcomes_tab <- do.call(cbind, all_outcomes)
all_outcomes_tab <- all_outcomes_tab[,-which(names(all_outcomes_tab)=='Characteristic')[2:3]]



# Clean MICE Probabilities -------------------------------------------------------


# Read in the sheets to create `current_table`
current_table_a  <- read_excel('../tables/table2-mice/mice-probabilities.xlsx', sheet='binaryattitude3_adj')
names(current_table_a)[1] <- 'Covariate'
names(current_table_a)[2] <- 'binaryattitude3'

current_table_b  <- read_excel('../tables/table2-mice/mice-probabilities.xlsx', sheet='binaryattitude4_adj')
names(current_table_b)[1] <- 'Covariate'
names(current_table_b)[2] <- 'binaryattitude4'

current_table_c  <- read_excel('../tables/table2-mice/mice-probabilities.xlsx', sheet='pillsmax_adj')
names(current_table_c)[1] <- 'Covariate'
names(current_table_c)[2] <- 'pillsmax'

current_table <- cbind(cbind(current_table_a, current_table_b[,2]), current_table_c[,2])

current_table <- current_table %>%
  mutate(binaryattitude3=invlogit(binaryattitude3)) %>%
  mutate(binaryattitude4=invlogit(binaryattitude4)) %>%
  mutate(pillsmax=invlogit(pillsmax))

current_table <- current_table %>%
  mutate(binaryattitude3=rounded_percent(binaryattitude3)) %>%
  mutate(binaryattitude4=rounded_percent(binaryattitude4)) %>%
  mutate(pillsmax=rounded_percent(pillsmax))




# Can we easily merge them ....
temp_merge <- left_join(all_outcomes_tab, current_table %>% rename(Characteristic=Covariate))

# dir.create('../data/step-3')
# saveRDS(temp_merge, file='../data/step-3/temp-merge2.RDS')



# MICE Confidence Intervals ---------------------------------------------------

# excel_sheets('../tables/table2-mice/mice-prob-se.xlsx')
ci_a  <- read_excel('../tables/table2-mice/mice-prob-se.xlsx', sheet='binaryattitude3_se')
ci_b  <- read_excel('../tables/table2-mice/mice-prob-se.xlsx', sheet='binaryattitude4_se')
ci_c  <- read_excel('../tables/table2-mice/mice-prob-se.xlsx', sheet='pillsmax_se')


rounded_percent <- Vectorize(rounded_percent)

ci_a[,3:6] <- rounded_percent(invlogit(ci_a[,3:6]))
ci_b[,3:6] <- rounded_percent(invlogit(ci_b[,3:6]))
ci_c[,3:6] <- rounded_percent(invlogit(ci_c[,3:6]))


names(ci_a)[2] <-  'Characteristic'
names(ci_a)[3] <- 'binaryattitude3'
ci_a <- ci_a %>%
  mutate(binaryattitude3_ci=paste0('(', `95% lower bound`, ', ', `95% upper bound`, ')')) %>%
  select(Characteristic, binaryattitude3, binaryattitude3_ci)


names(ci_b)[2] <-  'Characteristic'
names(ci_b)[3] <- 'binaryattitude4'
ci_b <- ci_b %>%
  mutate(binaryattitude4_ci=paste0('(', `95% lower bound`, ', ', `95% upper bound`, ')')) %>%
  select(Characteristic, binaryattitude4, binaryattitude4_ci)


names(ci_c)[2] <-  'Characteristic'
names(ci_c)[3] <- 'pillsmax'
ci_c <- ci_c %>%
  mutate(pillsmax_ci=paste0('(', `95% lower bound`, ', ', `95% upper bound`, ')')) %>%
  select(Characteristic, pillsmax, pillsmax_ci)


temp_merge1  <- left_join(temp_merge, ci_a)
temp_merge1b <- left_join(temp_merge1, ci_b)
temp_merge1c <- left_join(temp_merge1b, ci_c)




# MICE Bivariate Confidence Intervals -----------------------------------------s

# excel_sheets('../tables/table2-mice/mice-prob-se.xlsx')
ci_a2  <- read_excel('../tables/table2-mice/bivariate-prob-se.xlsx', sheet='binaryattitude3_se')
ci_b2  <- read_excel('../tables/table2-mice/bivariate-prob-se.xlsx', sheet='binaryattitude4_se')
ci_c2  <- read_excel('../tables/table2-mice/bivariate-prob-se.xlsx', sheet='pillsmax_se')



ci_a2[,3:6] <- rounded_percent(invlogit(ci_a2[,3:6]))
ci_b2[,3:6] <- rounded_percent(invlogit(ci_b2[,3:6]))
ci_c2[,3:6] <- rounded_percent(invlogit(ci_c2[,3:6]))


names(ci_a2)[2] <-  'Characteristic'
names(ci_a2)[3] <- 'binaryattitude3_bv'
ci_a2 <- ci_a2 %>%
  mutate(binaryattitude3_ci_bv=paste0('(', `95% lower bound`, ', ', `95% upper bound`, ')')) %>%
  select(Characteristic, binaryattitude3_bv, binaryattitude3_ci_bv)


names(ci_b2)[2] <-  'Characteristic'
names(ci_b2)[3] <- 'binaryattitude4_bv'
ci_b2 <- ci_b2 %>%
  mutate(binaryattitude4_ci_bv=paste0('(', `95% lower bound`, ', ', `95% upper bound`, ')')) %>%
  select(Characteristic, binaryattitude4_bv, binaryattitude4_ci_bv)


names(ci_c2)[2] <-  'Characteristic'
names(ci_c2)[3] <- 'pillsmax_bv'
ci_c2 <- ci_c2 %>%
  mutate(pillsmax_ci_bv=paste0('(', `95% lower bound`, ', ', `95% upper bound`, ')')) %>%
  select(Characteristic, pillsmax_bv, pillsmax_ci_bv)


temp_merge2  <- left_join(temp_merge1c, ci_a2)
temp_merge2b <- left_join(temp_merge2, ci_b2)
temp_merge2c <- left_join(temp_merge2b, ci_c2)



# Clean the p-values --------------------------------------------------

# In the future, we can round these values to a certain decimal point.
# For now, keep long so reviewers can fully see how it should look like.

ba3_df <- readPvalues('binaryattitude3')
ba4_df <- readPvalues('binaryattitude4')
pm_df  <- readPvalues('pillsmax')

pvalues_join <- left_join(left_join(ba3_df, ba4_df), pm_df)
pvalues_join <- pvalues_join %>%
  
  # Uppercase covariate names
  mutate(covariate=stringr::str_to_title(covariate)) %>%
  
  # Rename for merging
  rename(Characteristic=covariate) %>%
  rename(pval_ba3=binaryattitude3) %>%
  rename(pval_ba4=binaryattitude4) %>%
  rename(pval_pm=pillsmax) %>%

  # Significance of p-values
  mutate(pval_ba3b=ifelse(as.numeric(pval_ba3)<0.05, '*', '')) %>%
  mutate(pval_ba4b=ifelse(as.numeric(pval_ba4)<0.05, '*', '')) %>%
  mutate(pval_pmb=ifelse(as.numeric(pval_pm)<0.05, '*', '')) %>%
  
  # Clean up anything that might say "0" as a p-value
  mutate(pval_ba3=ifelse(as.numeric(pval_ba3)<0.001, '<0.001', pval_ba3)) %>%
  mutate(pval_ba4=ifelse(as.numeric(pval_ba4)<0.001, '<0.001', pval_ba4)) %>%
  mutate(pval_pm=ifelse(as.numeric(pval_pm)<0.001, '<0.001', pval_pm))
  


table_1 <- readr::read_csv('../tables/clean-csv/table1.csv')
temp_merge_2d <- left_join(table_1[,1] %>% rename(Characteristic=Covariate), temp_merge2c)
# saveRDS(pvalues_join, '../data/step-3/pvalues-join.RDS')
           
temp_merge3 <- left_join(temp_merge_2d, pvalues_join)



# Clean the p-values (Bivariate) --------------------------------------------------

# In the future, we can round these values to a certain decimal point.
# For now, keep long so reviewers can fully see how it should look like.

ba3_df2 <- readPvalues('binaryattitude3-bivariate')
ba4_df2 <- readPvalues('binaryattitude4-bivariate')
pm_df2  <- readPvalues('pillsmax-bivariate')

pvalues_join2 <- left_join(left_join(ba3_df2, ba4_df2), pm_df2)
pvalues_join2 <- pvalues_join2 %>%
  
  # Uppercase covariate names
  mutate(covariate=stringr::str_to_title(covariate)) %>%
  
  # Rename for merging
  rename(Characteristic=covariate) %>%
  rename(pval_ba3_bv=`binaryattitude3-bivariate`) %>%
  rename(pval_ba4_bv=`binaryattitude4-bivariate`) %>%
  rename(pval_pm_bv=`pillsmax-bivariate`) %>%
  
  # Significance of p-values
  mutate(pval_ba3b_bv=ifelse(as.numeric(pval_ba3_bv)<0.05, '*', '')) %>%
  mutate(pval_ba4b_bv=ifelse(as.numeric(pval_ba4_bv)<0.05, '*', '')) %>%
  mutate(pval_pmb_bv=ifelse(as.numeric(pval_pm_bv)<0.05, '*', '')) %>%
  
  # Clean up anything that might say "0" as a p-value
  mutate(pval_ba3_bv=ifelse(as.numeric(pval_ba3_bv)<0.001, '<0.001', pval_ba3_bv)) %>%
  mutate(pval_ba4_bv=ifelse(as.numeric(pval_ba4_bv)<0.001, '<0.001', pval_ba4_bv)) %>%
  mutate(pval_pm_bv=ifelse(as.numeric(pval_pm_bv)<0.001, '<0.001', pval_pm_bv))


# saveRDS(pvalues_join2, '../data/step-3/pvalues-join2.RDS')

temp_merge4 <- left_join(temp_merge3, pvalues_join2)



# Reorder Variables -----------------------------------------------------------

temp_merge5 <- temp_merge4 %>%
  select(Characteristic,
         `Strongly Agree/Agree (Unweighted)`,
         `Strongly Agree/Agree (%)`,
         `binaryattitude3_bv`,
         `binaryattitude3_ci_bv`,
         `pval_ba3_bv`,
         `pval_ba3b_bv`,
         `binaryattitude3`,
         `binaryattitude3_ci`,
         `pval_ba3`,
         `pval_ba3b`,
         
         `Strongly Agree/Agree (Unweighted).1`,
         `Strongly Agree/Agree (%).1`,
         `binaryattitude4_bv`,
         `binaryattitude4_ci_bv`,
         `pval_ba4_bv`,
         `pval_ba4b_bv`,
         `binaryattitude4`,
         `binaryattitude4_ci`,
         `pval_ba4`,
         `pval_ba4b`,
         
         `Strongly Agree/Agree (Unweighted).2`,
         `Strongly Agree/Agree (%).2`,
         `pillsmax_bv`,
         `pillsmax_ci_bv`,
         `pval_pm_bv`,
         `pval_pmb_bv`,
         `pillsmax`,
         `pillsmax_ci`,
         `pval_pm`,
         `pval_pmb`) %>%
  
  replace(is.na(.), '')


no_renames <- temp_merge5

names(temp_merge5) <- c('Characteristic',
                     rep(c('Unweighted', 'Weighted', 'MICE Bivariate', 'Bivariate 95% CI', 'Group P-value', 'Group Significance', 'MICE Adjusted', '95% CI', 'Group P-Value', 'Group Significance'), 3))

temp_merge6 <- rbind(names(temp_merge5), temp_merge5)



# Clean Row Names --------------------------------------------------

clean_table <- temp_merge6
clean_table$Characteristic <- stringr::str_to_title(clean_table$Characteristic)
clean_table$Characteristic <- gsub('To', 'to', clean_table$Characteristic)
clean_table$Characteristic <- gsub('Race', 'Race/Ethnicity', clean_table$Characteristic)
clean_table$Characteristic <- gsub('Educ', 'Education', clean_table$Characteristic)
clean_table$Characteristic <- gsub('Marital', 'Marital Status', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Proxy$', 'Proxy Status', clean_table$Characteristic)
clean_table$Characteristic <- gsub('Regularmeds', 'Regular Medications', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Dementia$', 'Dementia Classification', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Diagnosis$', 'Reported Dementia Diagnosis', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Health$', 'Self-Rated Health', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Hospitalized$', 'Hospitalized in Past Year', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Fall$', 'Fall in Past Month', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Doctor$', 'Seen Regular Doctor in Past Year', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Medicationsiadl$', 'Difficulty Tracking Medications', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Adls$', 'ADL Difficulties', clean_table$Characteristic)
clean_table$Characteristic <- gsub('^Chronic$', 'Chronic Conditions', clean_table$Characteristic)







names(clean_table) <- c('',
                     outcome_vars[1], '', '', '', '', '', '', '', '', '',
                     outcome_vars[2], '', '', '', '', '', '', '', '', '',
                     outcome_vars[3], '', '', '', '', '', '', '', '', '')




dir.create('../tables/clean-csv')
write.csv(clean_table, '../tables/clean-csv/table2-v2.csv', row.names=FALSE)


# Removal of Bivariate MICE ---------------------------------------------------
# names(no_renames)

no_renames <- no_renames %>%
  select(Characteristic,
         `Strongly Agree/Agree (Unweighted)`,
         `Strongly Agree/Agree (%)`,
         `binaryattitude3`,
         `binaryattitude3_ci`,
         `pval_ba3`,
         `pval_ba3b`,
         
         `Strongly Agree/Agree (Unweighted).1`,
         `Strongly Agree/Agree (%).1`,
         `binaryattitude4`,
         `binaryattitude4_ci`,
         `pval_ba4`,
         `pval_ba4b`,
         
         `Strongly Agree/Agree (Unweighted).2`,
         `Strongly Agree/Agree (%).2`,
         `pillsmax`,
         `pillsmax_ci`,
         `pval_pm`,
         `pval_pmb`) %>%
  
  replace(is.na(.), '')

no_renames_v2 <- no_renames %>%
  rename(unweighted_1=`Strongly Agree/Agree (Unweighted)`) %>%
  rename(weighted_1=`Strongly Agree/Agree (%)`) %>%
  mutate(mice_1=paste0(binaryattitude3, ' ', binaryattitude3_ci)) %>%
  
  rename(unweighted_2=`Strongly Agree/Agree (Unweighted).1`) %>%
  rename(weighted_2=`Strongly Agree/Agree (%).1`) %>%
  mutate(mice_2=paste0(binaryattitude4, ' ', binaryattitude4_ci)) %>%
  
  rename(unweighted_3=`Strongly Agree/Agree (Unweighted).2`) %>%
  rename(weighted_3=`Strongly Agree/Agree (%).2`) %>%
  mutate(mice_3=paste0(pillsmax, ' ', pillsmax_ci)) %>%
  
  select(Characteristic,
         unweighted_1,
         weighted_1,
         mice_1,
         `pval_ba3`,
         `pval_ba3b`,
         
         
         unweighted_2,
         weighted_2,
         mice_2,
         `pval_ba4`,
         `pval_ba4b`,
         
         unweighted_3,
         weighted_3,
         mice_3,
         `pval_pm`,
         `pval_pmb`)

no_renames_v2 <- no_renames_v2 %>% mutate(Characteristic=stringr::str_to_title(Characteristic))


names(no_renames_v2) <- c('Characteristic',
                        rep(c('Unweighted', 'Weighted', 'MICE Adjusted', 'Group P-Value', 'Group Significance'), 3))

no_renames_v3 <- rbind(names(no_renames_v2), no_renames_v2)

no_renames_v3$Characteristic <- stringr::str_to_title(clean_table$Characteristic)
no_renames_v3$Characteristic <- gsub('To', 'to', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('Race', 'Race/Ethnicity', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('Educ', 'Education', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('Marital', 'Marital Status', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Proxy$', 'Proxy Status', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('Regularmeds', 'Regular Medications', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Dementia$', 'Dementia Classification', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Diagnosis$', 'Reported Dementia Diagnosis', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Health$', 'Self-Rated Health', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Hospitalized$', 'Hospitalized in Past Year', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Fall$', 'Fall in Past Month', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Doctor$', 'Seen Regular Doctor in Past Year', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Medicationsiadl$', 'Difficulty Tracking Medications', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Adls$', 'ADL Difficulties', no_renames_v3$Characteristic)
no_renames_v3$Characteristic <- gsub('^Chronic$', 'Chronic Conditions', no_renames_v3$Characteristic)





names(no_renames_v3) <- c('',
                        outcome_vars[1], '', '', '', '',
                        outcome_vars[2], '', '', '', '',
                        outcome_vars[3], '', '', '', '')

dir.create('../tables/clean-csv')
write.csv(no_renames_v3, '../tables/clean-csv/table2-v2.csv', row.names=FALSE)

  