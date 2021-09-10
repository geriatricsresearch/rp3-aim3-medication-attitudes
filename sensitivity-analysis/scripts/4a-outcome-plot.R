# Created: 2021-06-18
# Updated: 2021-08-26


library(ggplot2)
library(readr)
library(readxl)
library(dplyr)
library(stringr)
library(RColorBrewer)


invlogit <- function(k) exp(k) / (1 + exp(k))
rounded_percent <- function(m) paste0(round(m*100, 0), '%')


# - # - # - # - # - # - # - # - # - #
#            READ DATA              #
# - # - # - # - # - # - # - # - # - #


table_2 <- read.csv('../tables/clean-csv/table2.csv')
correct_covariate_names <- table_2 %>% filter(`X.1`=='') %>% pull(X)


ba3_mice <- read_excel('../tables/table2-mice/mice-prob-se.xlsx', sheet='binaryattitude3_se')
ba4_mice <- read_excel('../tables/table2-mice/mice-prob-se.xlsx', sheet='binaryattitude4_se')
pm_mice  <- read_excel('../tables/table2-mice/mice-prob-se.xlsx', sheet='pillsmax_se')


names(ba3_mice)  <- c('Covariate', 'Category', 'Coefficient', 'SE', 'LB', 'UB')
ba3_mice$Outcome <- rep('Excess')

names(ba4_mice)  <- c('Covariate', 'Category', 'Coefficient', 'SE', 'LB', 'UB')
ba4_mice$Outcome <- rep('Deprescribe')

names(pm_mice)  <- c('Covariate', 'Category', 'Coefficient', 'SE', 'LB', 'UB')
pm_mice$Outcome <- rep('Pills')



# - # - # - # - # - # - # - # - # - #
#      CREATE POOLED DATA           #
# - # - # - # - # - # - # - # - # - #

pooled_data <- rbind(rbind(ba3_mice, ba4_mice), pm_mice)

pooled_data <- pooled_data %>%
  mutate(Coefficient=invlogit(Coefficient)) %>%
  mutate(LB=invlogit(LB)) %>%
  mutate(UB=invlogit(UB))
  


unique_long_labels <- unique(pooled_data$Covariate)
label_library <- data.frame(cbind(Characteristic=correct_covariate_names, Covariate=unique_long_labels))

levels_create <- left_join(label_library, pooled_data %>% select(Covariate, Category))
levels_create <- levels_create[!duplicated(levels_create),]

levels_create <- levels_create %>%
  group_by(Covariate) %>%
  mutate(the_levels=1:n())



pooled_data <- left_join(label_library, pooled_data)
pooled_data <- left_join(pooled_data, levels_create)

dir.create('../data/step-4')
saveRDS(pooled_data, '../data/step-4/pooled-data.RDS')



pooled_data$the_levels <- factor(pooled_data$the_levels, levels=c(1,2,3,4))


pooled_data <- pooled_data %>%
  mutate(Outcome=ifelse(Outcome=='Excess', 'Believe At Least One Medication No Longer Needed', Outcome)) %>%
  mutate(Outcome=ifelse(Outcome=='Deprescribe', 'Willing To Deprescribe If Doctor Said Possible', Outcome)) %>%
  mutate(Outcome=ifelse(Outcome=='Pills', 'Uncomfortable Taking 5 Or More Pills', Outcome)) %>%
  mutate(Outcome=factor(Outcome, levels=c('Believe At Least One Medication No Longer Needed',
                                          'Willing To Deprescribe If Doctor Said Possible',
                                          'Uncomfortable Taking 5 Or More Pills')))






# - # - # - # - # - # - # - # - # - #
#     CHANGE COVARIATE NAMES        #
# - # - # - # - # - # - # - # - # - #

cov_levels <- c("Age",
                "Sex",
                "Race/Ethnicity",
                "Education",
                "Married/Partnered",
                "Medicaid",
                "Chronic Conditions",
                "Regular Medications",
                "Self-Rated Health",
                "Dementia Classification",
                "Reported Dementia Diagnosis",
                "Proxy Status",
                "Hospitalized in Past Year",
                "Seen Regular Doctor in Past Year",
                "ADL Difficulties",
                "Difficulty Tracking Medications",
                "Fall in Past Month")

cat_levels <- c('no', 'yes',
                # '65 to 74', '75 to 84', '85+',
                '65-74', '75-84', '85+',
                'male', 'female', 
                'white, non-hispanic', 'black, non-hispanic', 'hispanic', 'other',
                'below high school', 'high school', 'beyond high school',
                # 'less than 6', '6 or more',
                '<6', '6+',
                '0-1', '2-3', '>3',
                'possible dementia', 'probable dementia',
                '<2', '2+',
                'fair/poor', 'good', 'excellent/very good',
                'sample person', 'proxy respondent')




# Thanks, Hadley.
# Source: https://github.com/tidyverse/stringr/issues/107
str_wrap_factor <- function(x, width) {
  levels(x) <- stringr::str_wrap(levels(x), width)
  x
}

str_to_title_factor <- function(x, width) {
  levels(x) <- stringr::str_to_title(levels(x))
  x
}



d <- pooled_data %>%
  select(-Covariate) %>%
  rename(Covariate=Characteristic)


d2 <- d %>%

  mutate(Covariate=ifelse(Covariate=='Dementia Diagnosis',
                          'Dementia Diagnosis Reported',
                          Covariate)) %>%

  mutate(Covariate=ifelse(Covariate=='Marital Status',
                          'Married/Partnered',
                          Covariate)) %>%

  mutate(Covariate=ifelse(Covariate=='ADLs',
                          'ADL Difficulties',
                          Covariate)) %>%

  mutate(Category=ifelse(Category %in% c('does not have medicaid', 'no dementia diagnosis',
                                         'not hospitalized', 'did not see doctor', 'no difficulty',
                                         'no falls', 'separated, divorced, widowed, never married'),
                         'no',
                         Category)) %>%

  mutate(Category=ifelse(Category %in% c('has medicaid', 'dementia diagnosed',
                                         'hospitalized', 'seen doctor', 'difficulty',
                                         'fallen', 'married or living with partner'),
                         'yes',
                         Category)) %>%

  mutate(Category=ifelse(Category=='65 to 74', '65-74', Category)) %>%
  mutate(Category=ifelse(Category=='85 +', '85+', Category)) %>%
  mutate(Category=ifelse(Category=='75 to 84', '75-84', Category)) %>%

  mutate(Category=ifelse(Category=='less than 6', '<6', Category)) %>%
  mutate(Category=ifelse(Category=='6 or more', '6+', Category)) %>%
  mutate(Category=ifelse(Category=='>=2', '2+', Category))
  

d2 <- d2 %>%
  mutate(the_levels=ifelse(Category=='no', 1, the_levels)) %>%
  mutate(the_levels=ifelse(Category=='yes', 2, the_levels)) %>%
  mutate(the_levels=ifelse(Category=='fair/poor', 1, the_levels)) %>%
  mutate(the_levels=ifelse(Category=='good', 2, the_levels)) %>%
  mutate(the_levels=ifelse(Category=='excellent/very good', 3, the_levels)) %>%
  mutate(the_levels=factor(the_levels))




d2 %>%
  
  mutate(Covariate=factor(Covariate, levels=cov_levels)) %>%
  mutate(Category=factor(Category, levels=cat_levels)) %>%
  mutate(Covariate=str_wrap_factor(Covariate, width=20)) %>%
  mutate(Category=str_wrap_factor(Category, width=25)) %>%
  mutate(Category=str_to_title_factor(Category)) %>%
  mutate(Outcome=str_wrap_factor(Outcome, width=35)) %>%
  
  ggplot(aes(x=Coefficient, y=Category, xmin=LB, xmax=UB, col=the_levels)) +
  geom_point(shape='square', col='black') +
  geom_linerange(alpha=0.7, lwd=2) +
  facet_grid(Covariate~Outcome, scales='free_y', switch='both') +
  
  theme_bw() +
  theme(strip.text.y.left=element_text(angle=0),
        strip.placement='outside',
        legend.position='none') +
  scale_y_discrete(limits=rev) +
  ylab('') +
  xlab('')
ggsave(filename='../plots/attitude-agreements.png', width=12, height=9)



