# * Script Setup -------------------------------------------- *
# *
# * | Author    | Edie Espejo
# * | Study     | RP3 Aim 3 (Matthew Growdon)
# * | Created   | x
# * | Last Edit | x
# * | Objective | Clean data for tables

library(scales)

# //////////////////////////// T A B L E .. O N E ////////////////////////////
tbl1_files <- list.files('../tables/table1', full.names=TRUE, pattern='csv')

tbl1_order <- 'age sex race educ marital medicaid chronic regularmeds health dementia diagnosis hospitalized doctor adls medicationsiadl fall'
tbl1_order <- strsplit(x=tbl1_order, split=' ')[[1]]


read_tbl1_output <- function(m) {
  
  these_files <- tbl1_files[which(grepl(pattern=tbl1_order[m], tbl1_files))]
  these_tabs  <- lapply(these_files, read.delim)
  
  categories <- these_tabs[[1]][,1]
  unwgt_cnts <- comma(these_tabs[[1]][,2])
  wgt_percent <- paste0(round(as.numeric(these_tabs[[3]][,2]) * 100, 0), '%')

  the_tab   <- data.frame(cbind(categories, unwgt_cnts, wgt_percent))
  
  sub_labels  <- c(stringr::str_to_title(tbl1_order[m]), '', '')
  the_tab   <- the_tab[-nrow(the_tab),]
  the_tab   <- rbind(sub_labels, the_tab)
  names(the_tab) <- c('Covariate',
                      'Unweighted Respondents, No.',
                      'National Estimate, (%)')
  
  the_tab
}

# Create table.
tbl1_rows <- lapply(1:length(tbl1_order), read_tbl1_output)
tbl1_draft <- do.call(rbind, tbl1_rows)

# Clean names up!
tbl1_draft$Covariate <- stringr::str_to_title(tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('To', 'to', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('Race', 'Race/Ethnicity', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('Educ', 'Education', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('Marital', 'Marital Status', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('Regularmeds', 'Regular Medications', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Dementia$', 'Dementia Classification', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Diagnosis$', 'Reported Dementia Diagnosis', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Health$', 'Self-Rated Health', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Hospitalized$', 'Hospitalized in Past Year', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Fall$', 'Fall in Past Month', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Doctor$', 'Seen Regular Doctor in Past Year', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Medicationsiadl$', 'Difficulty Tracking Medications', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Adls$', 'ADL Difficulties', tbl1_draft$Covariate)
tbl1_draft$Covariate <- gsub('^Chronic$', 'Chronic Conditions', tbl1_draft$Covariate)






# if (!dir.exists('../tables/clean-csv/')) dir.create('../tables/clean-csv/')
# write.csv(tbl1_draft, '../tables/clean-csv/table1.csv', row.names=FALSE)




# Weighted Counts?
# Edit: 2021-08-20
library(dplyr)
starts <- which(tbl1_draft$`Unweighted Respondents, No.`=='')
starts <- starts+1
ends   <- starts-2
ends   <- ends[-1]
ends   <- c(ends, nrow(tbl1_draft))

total_n <- sum(as.numeric(tbl1_draft$`Unweighted Respondents, No.`[starts[1]:ends[1]]))

tbl1_draft <- tbl1_draft %>%
  mutate(`Weighted Respondents, Dec.`=ifelse(`Unweighted Respondents, No.`!='',
                                            as.numeric(gsub('%', '', `National Estimate, (%)`))/100 * total_n,
                                            '')) %>%
  mutate(`Weighted Respondents, No.`=ifelse(`Unweighted Respondents, No.`!='',
                                            round(as.numeric(`Weighted Respondents, Dec.`),0),
                                            ''))


if (!dir.exists('../tables/clean-csv/')) dir.create('../tables/clean-csv/')
write.csv(tbl1_draft, '../tables/clean-csv/table1.csv', row.names=FALSE)
