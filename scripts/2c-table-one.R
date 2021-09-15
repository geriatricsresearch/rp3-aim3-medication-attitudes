# Code By: Edie Espejo
# Author:  Matthew Growdon
# Project: RP3 Aim 3
# Created: 2021-04-15
# Edited:  2021-09-15

library(scales)
library(dplyr)


# Table 1 Function ------------------------------------------------------------
read_tbl1_output <- function(tbl1_files, tbl1_order, m) {
  
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



# Table 1 Files ---------------------------------------------------------------
tbl1_files <- list.files('../tables/table1', full.names=TRUE, pattern='csv')

tbl1_order <- 'age sex race educ marital medicaid chronic regularmeds health dementia diagnosis proxy hospitalized doctor adls medicationsiadl fall'
tbl1_order <- strsplit(x=tbl1_order, split=' ')[[1]]


# Generate Table 1  -----------------------------------------------------------
tbl1_rows <- lapply(1:length(tbl1_order), function(k) read_tbl1_output(tbl1_files, tbl1_order, k))
tbl1_draft <- do.call(rbind, tbl1_rows)



# if (!dir.exists('../tables/clean-csv/')) dir.create('../tables/clean-csv/')
# write.csv(tbl1_draft, '../tables/clean-csv/table1.csv', row.names=FALSE)




# Add Weighted Counts ---------------------------------------------------------
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





# Self Only -------------------------------------------------------------------
tbl1_files_b <- list.files('../tables/table1-self', full.names=TRUE, pattern='csv')

tbl1_order_b <- 'age sex race educ marital medicaid chronic regularmeds health dementia diagnosis hospitalized doctor adls medicationsiadl fall'
tbl1_order_b <- strsplit(x=tbl1_order_b, split=' ')[[1]]


tbl1_rows_b  <- lapply(1:length(tbl1_order_b), function(k) read_tbl1_output(tbl1_files_b, tbl1_order_b, k))
tbl1_draft_b <- do.call(rbind, tbl1_rows_b)

num_sp <- sum(as.numeric(tbl1_draft_b[2:4,2]))

self_a <- tbl1_draft_b[1:39,]
self_b <- data.frame(rbind(c('Proxy', '', ''),
                           c('sample person', num_sp, '100%'),
                           c('proxy respondent', '0', '0%')))
names(self_b) <- names(tbl1_draft_b)
self_c <- tbl1_draft_b[40:nrow(tbl1_draft_b),]

tbl1_self <- rbind(self_a, self_b, self_c)
names(tbl1_self)[2:3] <- paste0(names(tbl1_self)[2:3], ' - Self')


# Proxy Only ------------------------------------------------------------------
tbl1_files_c <- list.files('../tables/table1-proxy', full.names=TRUE, pattern='csv')

tbl1_order_c <- 'age sex race educ marital medicaid chronic regularmeds health dementia diagnosis hospitalized doctor adls medicationsiadl fall'
tbl1_order_c <- strsplit(x=tbl1_order_c, split=' ')[[1]]

tbl1_rows_c  <- lapply(1:length(tbl1_order_c), function(k) read_tbl1_output(tbl1_files_c, tbl1_order_c, k))
tbl1_draft_c <- do.call(rbind, tbl1_rows_c)

num_proxy <- sum(as.numeric(tbl1_draft_c[2:4,2]))

proxy_a <- tbl1_draft_c[1:39,]
proxy_b <- data.frame(rbind(c('Proxy', '', ''),
                           c('sample person', '0', '0%'),
                           c('proxy respondent', num_proxy, '100%')))
names(proxy_b) <- names(tbl1_draft_c)
proxy_c <- tbl1_draft_c[40:nrow(tbl1_draft_c),]

tbl1_proxy<- rbind(proxy_a, proxy_b, proxy_c)
names(tbl1_proxy)[2:3] <- paste0(names(tbl1_proxy)[2:3], ' - Proxy')


# Proxy Only ------------------------------------------------------------------
temp_merge <- left_join(tbl1_draft[,1:3], tbl1_self)
temp_merge <- left_join(temp_merge, tbl1_proxy)

temp_merge$`Unweighted Respondents, No. - Self` <- as.integer(temp_merge$`Unweighted Respondents, No. - Self`)
temp_merge$`Unweighted Respondents, No. - Proxy` <- as.integer(temp_merge$`Unweighted Respondents, No. - Proxy`)
temp_merge[is.na(temp_merge)] <- ''

# Clean Names -----------------------------------------------------------------
temp_merge$Covariate <- stringr::str_to_title(temp_merge$Covariate)
temp_merge$Covariate <- gsub('To', 'to', temp_merge$Covariate)
temp_merge$Covariate <- gsub('Race', 'Race/Ethnicity', temp_merge$Covariate)
temp_merge$Covariate <- gsub('Educ', 'Education', temp_merge$Covariate)
temp_merge$Covariate <- gsub('Marital', 'Marital Status', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Proxy$', 'Proxy Status', temp_merge$Covariate)
temp_merge$Covariate <- gsub('Regularmeds', 'Regular Medications', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Dementia$', 'Dementia Classification', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Diagnosis$', 'Reported Dementia Diagnosis', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Health$', 'Self-Rated Health', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Hospitalized$', 'Hospitalized in Past Year', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Fall$', 'Fall in Past Month', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Doctor$', 'Seen Regular Doctor in Past Year', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Medicationsiadl$', 'Difficulty Tracking Medications', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Adls$', 'ADL Difficulties', temp_merge$Covariate)
temp_merge$Covariate <- gsub('^Chronic$', 'Chronic Conditions', temp_merge$Covariate)

if (!dir.exists('../tables/clean-csv/')) dir.create('../tables/clean-csv/')
write.csv(temp_merge, '../tables/clean-csv/table1-stratified.csv', row.names=FALSE)

