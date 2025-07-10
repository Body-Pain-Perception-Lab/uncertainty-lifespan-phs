# Load required packages

get_data = function(){
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(ggplot2, readr, reshape, pracma, purrr, stringr, tidyverse)
  
  # functions
  datFile = list.files(file.path(here::here('data')), pattern='.csv', full.names = TRUE)
  dat_hc = read.csv(datFile[2], sep=',', header = TRUE)
  dat_p = read.csv(datFile[4], sep=',', header = TRUE)
  
  functions = list.files(file.path(here::here('data','analysis","functions')), full.names = TRUE)
  sapply(functions, source)
  # TCF function
  TCF = function(t1,t2,tmin,tmax){
    TCF = (t2-t1)/(tmax-tmin)
  }
  
  # first - demographics
  demo_sum <- aggregate(age ~ subject * gender, mean, data = dat_hc)
  demo_sum %>% count(gender)
  
  fprintf('Mean age: %s', round(mean(demo_sum$age),2))
  fprintf('\nMin age: %s', min(demo_sum$age))
  fprintf('\nMax age: %s', max(demo_sum$age))
  
  # plot age range
  age_plot <- demo_sum %>% 
    arrange(age) %>% 
    mutate(count = row_number()) %>%
    ggplot() +
    geom_point(aes(count, age, colour = gender)) +
    theme_bw() +
    theme()
  
  age_plot
  
  qs = read_csv(file.path(here::here("..","..","..","mnt","slow_scratch","ageing-and-neuropathy",'age_redcap_temp1.csv')))
  
  ###### HEALTHY CONTROL ANALYSIS FIRST
  ## MNSI SCORE, load and check < 7
  age_MNSI = qs %>% 
    select(id, record_id, numb:amputation_da) %>% 
    mutate(f_lelsesl_se = coalesce(f_lelsesl_se, numb),                                       ### Current starts here 
           br_ndende = coalesce(br_ndende, burning),
           f_lsomme = coalesce(f_lsomme, sensitive),
           muskelkramper = coalesce(muskelkramper, cramps),
           prikkende = coalesce(prikkende, prickling),
           dynen = coalesce(dynen, covers),
           varme_kulde = coalesce(varme_kulde, hot_cold),
           s_r = coalesce(s_r, hot_cold),
           neuropati = coalesce(neuropati, neuropathy),
           svag = coalesce(svag, weak_mnsi),
           natten = coalesce(natten, worse_night),
           g_r = coalesce(g_r, walk),
           m_rke_f_dder = coalesce(m_rke_f_dder, sense_feet),
           spr_kker = coalesce(spr_kker, cracks),
           amputation_da = coalesce(amputation_da, cracks)) %>% 
    rowwise() %>%
    mutate(mnsi = sum(c_across(f_lelsesl_se:f_lsomme) == 1) 
           + sum(c_across(prikkende:dynen) == 1) 
           + sum(c_across(s_r:neuropati) == 1)
           + sum(c_across(natten:g_r) == 1)
           + sum(c_across(spr_kker:amputation_da) == 1)
           + if_else(varme_kulde == 2, 1, 0)
           + if_else(m_rke_f_dder == 2, 1, 0)) %>%
    select(id, record_id, mnsi)
  
  # correcting subject duplicates
  age_MNSI <- age_MNSI %>% 
    mutate(id = ifelse(record_id == 306, 1006, id)) %>% 
    mutate(id = ifelse(record_id == 262, 2007, id))
  
  dataMNSI = age_MNSI %>% 
    select(id, mnsi) %>%
    dplyr::rename(subject = id) %>%
    mutate(subject = paste0("sub-", subject))
  
  # combine with dat
  dat = left_join(dat_hc, dataMNSI, by="subject", relationship = "many-to-many")
  
  ### remove participants with < 7
  filtMNSI=dat%>%
    filter(mnsi >= 7)
  
  print(filtMNSI)
  
  dat %>% filter(!(subject %in% filtMNSI$subject)) #Gives us the initial dataset minus people with an MNSI score >= 7, however none of 
  
  ## language encoding
  # checking language coding to flip scoring of Danish even numbers (fixing coding error during data collection)
  lang1 = read.csv(file.path(here::here("..","..","..","mnt","slow_scratch","ageing-and-neuropathy", "languages","results.csv")))
  lang2 = read.csv(file.path(here::here("..","..","..","mnt","slow_scratch","ageing-and-neuropathy", "languages","results (1).csv")))
  
  lang = rbind(lang1,lang2)
  names(lang) = c("subject","language")
  
  # write.csv(lang,file.path(dirGit, "data", "language_instructions.csv"))
  
  dat = inner_join(lang,dat)
  dat = dat %>% mutate(num_sub = as.integer(gsub("sub-", "", subject))) %>% 
    mutate(even_sub = num_sub %% 2 == 0) %>% 
    mutate(tempResp = ifelse(even_sub & language == 2, 1-tempResp,tempResp)) 
  
  ## FILTER MAIN DATA
  # now work on data
  # generate vas rt (atm is time at vas response)
  dat <- dat %>% 
    dplyr::rename(vasTime = vasRT) %>% 
    mutate(vasRT = vasTime - vasOnset) 
  
  rtFilt = .250
  
  # flag tempRT and vasRT < .250 as NA
  # remove rows where buttonRT is > .250
  # also catch trials and where there is a binary choice made
  filtDat <- dat %>% 
    filter(buttonRT > .250,
           tempRT > .250,
           # catch == 0,
           !is.na(tempResp)) %>% 
    mutate(vasRating = ifelse(vasRT < .250, NA, vasRating))
  
  # identify any participants with < 3 trials per condition
  filtID <- filtDat %>% 
    group_by(subject,temp_cond) %>% 
    count(subject) %>% 
    filter(n < 3)
  
  filtDat <- 
    filtDat %>% filter(!(subject %in% filtID$subject))
  
  # TC vals, PHS column (recode of tempResp) and recoded VAS
  filtDat <- filtDat %>% 
    mutate(TC = TCF(tmin_temp, tmax_temp, 0, 50),
           TC = TC*100) %>% 
    mutate(PHS = ifelse(tempResp == 1, 0, 1),
           conf = vasRating/100,
           z_age = (age - 20)) #subtract minimum age, to standardise
  
  # calculate minimum RT for each subject
  filtDat <- filtDat %>% 
    group_by(subject) %>% 
    mutate(minRT = min(tempRT, na.rm = TRUE)) %>% ungroup()
  
  
  # save as new data-frame
  filtDat = filtDat %>% select(subject,group,age,gender,even_sub,language,trial,temp_cond,condition,tmax_temp,tmin_temp,
                               TC,tempResp,PHS,tempRT,vasRating, catch, duration)
  
  write.csv(filtDat, file.path("data", "phs-ageing_compiled-filtered.csv"), row.names = FALSE)
}