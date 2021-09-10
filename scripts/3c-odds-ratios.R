library(readxl)
library(dplyr)


tbl2_order <- 'age sex race educ marital medicaid chronic regularmeds health dementia diagnosis proxy hospitalized doctor adls medicationsiadl fall'
tbl2_order <- strsplit(x=tbl2_order, split=' ')[[1]]




readOddsRatios <- function(ba3_file) {
  
  ba3_sheets <- excel_sheets(ba3_file)
  ba3_sheets <- ba3_sheets %>% sort()
  unique_covariates <- unique(gsub('_[0-9]', '', ba3_sheets))
  

  starts <- seq(from=1, to=length(ba3_sheets), by=2)
  ends   <- starts-1
  ends   <- ends[-1]
  ends   <- c(ends, length(ba3_sheets))
  sequences_to_use <- lapply(1:length(starts), function(k) starts[k]:ends[k])
  
  
  full_list <- vector(mode='list')
  
  
  for (ix in 1:length(unique_covariates)) {
    i_seq       <- unlist(sequences_to_use[ix])
    sheets_i    <- ba3_sheets[i_seq]
    covariate_i <- gsub('_[0-3]', '', sheets_i[1])
    
    read_in <- lapply(sheets_i, function(k) read_excel(ba3_file, sheet=k))
    
    read_in[[1]] <- read_in[[1]] %>% mutate(Model='Bivariate') %>% mutate(Characteristic=covariate_i)
    names(read_in[[1]]) <- c('Category', 'Coefficient', 'SE', 'LB', 'UB', 'Model', 'Characteristic')
    read_in[[1]] <- read_in[[1]] %>% select(Characteristic, Category, Coefficient, SE, LB, UB)
    read_in[[1]] <- read_in[[1]] %>% mutate(Coefficient=exp(Coefficient)) %>% mutate(SE=exp(SE), LB=exp(LB), UB=exp(UB))
    names(read_in[[1]])[3:6] <- paste0(names(read_in[[1]])[3:6], ' - Bivariate')
    
    read_in[[2]] <- read_in[[2]] %>% mutate(Model='Adjusted') %>% mutate(Characteristic=covariate_i)
    names(read_in[[2]]) <- c('Category', 'Coefficient', 'SE', 'LB', 'UB', 'Model', 'Characteristic')
    read_in[[2]] <- read_in[[2]] %>% select(Characteristic, Category, Coefficient, SE, LB, UB)
    read_in[[2]] <- read_in[[2]] %>% mutate(Coefficient=exp(Coefficient)) %>% mutate(SE=exp(SE), LB=exp(LB), UB=exp(UB))
    names(read_in[[2]])[3:6] <- paste0(names(read_in[[2]])[3:6], ' - Adjusted')
    
    read_in_df <- cbind(cbind(read_in[[1]], read_in[[2]][3:6]))
    
    full_list[[covariate_i]] <- read_in_df
  }
  
  
  ordered_ba3_list <- lapply(tbl2_order, function(k) full_list[[k]])
  names(ordered_ba3_list) <- tbl2_order
  
  
  ba3_df <- do.call(rbind, ordered_ba3_list)
  row.names(ba3_df) <- 1:nrow(ba3_df)
  
  ba3_df <- apply(ba3_df, 2, function(k) ifelse(is.na(k), '', k))
  ba3_df <- data.frame(ba3_df)
  
  names(ba3_df) <- gsub('(\\.)+', ' - ', names(ba3_df))
  
  return(ba3_df)
  
}


ba3_df <- readOddsRatios('../tables/log-odds/binaryattitude3.xlsx')
ba4_df <- readOddsRatios('../tables/log-odds/binaryattitude4.xlsx')
pm_df  <- readOddsRatios('../tables/log-odds/pillsmax.xlsx')


write.csv(ba3_df, '../tables/clean-csv/odds-ratios-excess.csv')
write.csv(ba4_df, '../tables/clean-csv/odds-ratios-deprescribe.csv')
write.csv(pm_df, '../tables/clean-csv/odds-ratios-pills.csv')
