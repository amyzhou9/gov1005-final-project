library(tidyr)
library(tidytext)
library(lubridate)
library(tidyverse)
library(purrr)
library(stringr)
library(gt)
library(webshot)

# read in the supreme court data

supreme_court <- readRDS('clean-data/supreme_court.rds') 

# petitioner variables that indicate individuals

vars <- c(1, 8, 10, 11, 13, 16, 23, 100, 102, 106, 110, 111, 112, 123, 126, 129, 134, 136, 137, 138, 140,
          142, 145, 152, 153, 154, 155, 157, 162, 164, 166, 168, 169, 170, 172, 
          173, 174, 175, 179, 180, 182, 183, 188, 195, 200, 202, 204, 206, 211, 214, 222, 223, 224, 227, 
          233, 236, 239, 241, 247, 250, 251, 253, 254, 256, 257)

# I then selected the necessary variables for analysis and then filtered for
# where the petitioner is in the variable list and is hence and individual and
# then filtered for majority opinions.I then mutated the gender variable so that
# if the codebook indicated the individual was a female it was included as a female. 

supreme_court_name <- supreme_court %>% 
  select(petitioner, dateDecision, caseName, caseId, partyWinning, text, category) %>% 
  filter(petitioner %in% vars &
           category == "majority") %>% 
  mutate(gender = ifelse(
    (petitioner == 9 | petitioner == 11 | petitioner == 154 | petitioner == 155 |
      petitioner == 183 | petitioner == 253 | petitioner == 188), "female", "male/unknown"
  )) 

# Create labels for the facets
gender.labs <- c("female","male/unknown")
names(gender.labs) <- c("Female", "Male/Unknown")

# Created a model of partyWinning over time using qlogis as it is
# binary and then faceting it by gender

model <- supreme_court_name %>% 
  mutate(year = year(dateDecision),
         gender = as.factor(gender)) %>% 
  filter(partyWinning == 1 | partyWinning == 0) %>% 
  filter(gender == 1 | gender == 0) %>% 
  group_by(year, gender) %>% 
  summarise(perc_win = mean(partyWinning),
            emplogit = qlogis(perc_win)) %>% 
  ggplot(aes(x = year, y = emplogit)) +
  geom_point() +
  geom_smooth(method = "lm") +
  facet_grid(~gender) + 
  labs (
    title = "Cases Won by Petitioners",
    subtitle = "Faceted by Gender"
  ) +
  theme_classic() +
  ylab(
    "Empirical Logits"
  ) +
  xlab(
    "Year"
  )
  

model

# ggsave('caselaw_analysis/graphics/female_supreme.png')
# save the graph as an image for shiny

# I then made the gender and partywinning variables factors so that I could
# construct a binary model from it.


  

female  <- supreme_court_name %>% 
  mutate(gender = ifelse(gender == "female", 1, 0)) %>% 
  filter(partyWinning == 1 | partyWinning == 0) %>% 
  select(dateDecision, gender, partyWinning) %>% 
  mutate(year = year(dateDecision)) 
  

female
  



# I then used glm to make a model to predict how gender affects winning. I then
# created a gt table out of the tidy model.

female_model <- glm(partyWinning ~ gender, family = "binomial", data = female) %>% 
  tidy(conf.int = TRUE) %>% 
  select(term, estimate, conf.low, conf.high) %>% 
  gt() %>% 
  tab_header(
    "Gender and Likelihood of Winning Supreme Court Case"
  ) %>% 
  cols_label(
    term = "Term", 
    estimate = "Estimate", 
    conf.low = "Lower Bound", 
    conf.high = "Higher Bound"
  )
  

female_model
# I then saved the gt table to be used in shiny.

female_model %>% 

gtsave("female_model.html", inline_css = TRUE)  


# I am still working on this part to do sentiment analysis. 

words <- c("abortion", "guns", "harvard", "discrimination", "slavery", "defendant")


test_w <- c("abortion", "defendant")



supreme_court <- readRDS('clean-data/supreme_court.rds') 

total_year <- supreme_court %>% 
  mutate(year = year(decision_date)) %>% 
  group_by(year) %>% 
  summarise(total = n())


occurences <- supreme_court %>% 
  select(caseName, text, dateDecision) %>% 
  mutate(year = year(dateDecision)) %>% 
  mutate(words = paste(unlist(text), collapse = " ")) %>% 
  mutate(occurence = str_count(text, "abortion")) %>% 
  filter(occurence > 4) %>% 
  group_by(year) %>% 
  summarise(num_cases = n())
  

ratio <- full_join(total_year, occurences) %>% 
  mutate_all(~replace(.,is.na(.), 0))


by_year <- supreme_court %>% 
  select(decision_date, text) %>% 
  mutate(year = year(decision_date)) %>% 
  mutate(words = paste(unlist(text), collapse = " ")) %>% 
  mutate(occurence = str_count(text, "abortion")) %>% 
  filter(occurence > 4) %>% 
  select(year, words) %>% 
  group_by(year) %>% 
  summarise(text = paste(words,collapse = " "))


supreme_court <- readRDS('clean-data/supreme_court.rds')


supreme_abortion <- supreme_court %>% 
  select(caseName, text, dateDecision) %>% 
  mutate(year = year(dateDecision), 
         row = 1:nrow(.)) %>% 
  mutate(words = paste(unlist(text), collapse = " ")) %>% 
  mutate(occurence = str_count(text, "abortion")) %>% 
  filter(occurence > 4) %>% 
  select(caseName, words) %>% 
  head(2)





word_count <- function(x){
  
  supreme_court <- readRDS('clean-data/supreme_court.rds')
  
  simple <- supreme_court %>% 
    select(caseName, text) %>% 
    mutate(words = paste(unlist(text), collapse = " "))
  
  count <- simple %>% 
    slice(x) %>% 
    unnest_tokens(word, words) %>% 
    summarise(count = n())
  
  count
    
}


x <- tibble(count = map(c(1:10), ~word_count(.)))

test <- supreme_court %>% 
  head(2) %>% 
  mutate(row = 1:nrow(.)) %>% 
  mutate(word_count = map(row, ~ word_count(.)))



supreme_court_words <- supreme_abortion %>% 
  head(1) %>% 
  unnest_tokens(word, words) 

total_words <-  supreme_court %>% 
  head(1) %>% 
  unnest_tokens(word, words) %>% 
  summarise(total = n()) %>% 
  pull(total)

s <- supreme_court_words %>% 
  inner_join(get_sentiments("bing")) %>% 
  count(sentiment) %>% 
  spread(sentiment, n, fill = 0) %>% 
  mutate(intensity = positive + negative) %>% 
  mutate(ratio = intensity/total_words)


samoa <- readRDS('clean-data/samoa.rds') 

s <- samoa %>% 
  select(name, text) %>% 
  mutate(words = paste(unlist(text), collapse = " ")) %>% 
  unlist(words) %>% 
  select(name, text) %>% 
  head(1) 
  

sentiment_analysis <- function(row){
  w <- words %>% 
    unnest_tokens(word,words) %>% 
    summarise(count = n()) %>% 
    pull(count)
  
  w
}


apply(samoa, 1, sentiment_analysis)


samoa_data <- readRDS('clean-data/massachusetts.rds')

plot_data <- samoa_data %>% 
  select(name, decision_date, text, court_name) %>%
  mutate(year = year(decision_date)) %>% 
  group_by(year) %>% 
  summarise(total = n())


contains_data <- samoa_data %>% 
  select(decision_date, text) %>% 
  mutate(year = year(decision_date)) %>% 
  filter(grepl("Harvard", text)) %>% 
  group_by(year) %>% 
  summarise(contains = n())

ratio_data <- full_join(plot_data, contains_data) %>% 
  mutate_all(~replace(.,is.na(.), 0)) %>% 
  mutate(prop = contains/total) %>% 
  filter(year != 0) %>% 
  ggplot(aes(x = year, y = prop)) +
  geom_line()

ratio_data


  
  
 





  











