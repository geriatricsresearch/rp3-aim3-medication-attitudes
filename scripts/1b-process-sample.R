# -------------------------------------------------------------------------
# Script Setup       //////////////////////////////////////////////////////
#
# | Author    | Edie Espejo
# | Study     | RP3 Aim 3, Medications Attitudes (Matthew Growdon)
# | Created   | 2021-06-25
# | Last Edit | 2021-06-25
# | Objective | Define NHATS MA module subsample




# -------------------------------------------------------------------------
# Libraries          //////////////////////////////////////////////////////

library(readstata13)
library(dplyr)
library(ggplot2)



# -------------------------------------------------------------------------
# Data               //////////////////////////////////////////////////////

nhats_tracker  <- read.dta13('../data/nhats/NHATS_Round_6_Tracker_File_V3.dta',
                             nonint.factors=FALSE)
nhats_spfile   <- read.dta13('../data/nhats/NHATS_Round_6_SP_File_V2.dta',
                             nonint.factors=FALSE)
nhats_dementia <- read.dta13('../data/step-1/dementia-classified-nhats.dta',
                             nonint.factors=FALSE)

nhats_round5 <- read.dta13('../data/nhats/NHATS_Round_5_SP_File_V2.dta', nonint.factors=FALSE)
nhats_round5 <- nhats_round5 %>% dplyr::select(spid, el5higstschl)

nhats_round1 <- read.dta13('../data/nhats/NHATS_Round_1_SP_File.dta', nonint.factors=FALSE)
nhats_round1 <- nhats_round1 %>% dplyr::select(spid, el1higstschl)





# -------------------------------------------------------------------------
# Pipeline               //////////////////////////////////////////////////

# - **Tracker File V3**
#   - Original: $n=19,530$
#   - Keep only `r6status %in% c(60,63)`, i.e. either 60 or 63: $n=6,410$
#   - **SP File 2016 V2**
#   - Original: $n=7,276$
#   - Keep only `r6status %in% c(60,63)`: $n=6,410$
#   - Remove -1 Inapplicable categorical `age`: $n=6,410$
#   - None were applicable in this step.
# - Keep only `r6dresid==1` | `r6dresid==2`: $n=6,309$
#   - **NHATS Medication Attitudes Module**
#   - Drop `ma6attitude1==-1`: $n=2,096$
#   - **Merge with dementia scores**
#   - Left join the above with dementia classifications: $n=2,096$
#   - Keep if `r6demclass %in% c(1,2)`, i.e. possible or probable dementia
# - **Merge with Rounds 1 and 5 for EL Section**  
#   - Left join the above dataset with Round 5's `el5higstschl` variable
#   - Left join the above dataset with Round 1's `el1higstschl` variable


# Tracker File V3
nhats_sub_a <- nhats_tracker %>% filter(r6status %in% c(60,63))

# SP File 2016 V2
nhats_sub_b <- left_join(nhats_sub_a, nhats_spfile)
nhats_sub_b <- nhats_sub_b %>%
  filter(r6d2intvrage != -1) %>%
  filter(r6dresid %in% c(1,2))

# NHATS Medication Attitudes Module
nhats_sub_c <- nhats_sub_b %>% filter(ma6attitude1 != -1)

# Merge with dementia scores
nhats_sub_d <- left_join(nhats_sub_c, nhats_dementia)
nhats_sub_d <- nhats_sub_d %>% filter(!is.na(r6demclas))

# Merge with Rounds 1 and 5
nhats_sub_e <- left_join(nhats_sub_d, nhats_round5)
nhats_sub_f <- left_join(nhats_sub_e, nhats_round1)

nhats_sub_f <- nhats_sub_f %>%
  mutate(education=ifelse(el5higstschl==(-1), el1higstschl, el5higstschl))

nhats_sub_f <- nhats_sub_f %>% select(-c(el5higstschl, el1higstschl))



# -------------------------------------------------------------------------
# Export             //////////////////////////////////////////////////////

save.dta13(nhats_sub_f, '../data/step-1/nhats-ma-module.dta')
readr::write_csv(nhats_sub_d %>% data.frame(), '../data/step-1/nhats-ma-module.csv')
