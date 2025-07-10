entropy = function(p){
  entropy = -((p)*log(p)+(1-p)*log(1-p))
  return(entropy)
}

fit_model_m1 = function(parameters,df, test = F){
  
  if(test){
    samples = 10
  }else{
    samples = 500
  }
  
  # first initiate stan model
  stanHmodel1 <- cmdstanr::cmdstan_model(here::here("analysis","simulations","stanmodels",'phs-hierarchical_m1_vec.stan')) #initiate model
  
  
  ranges <- data.frame(
    start = seq(1, by = 64, length.out = length(unique(df$id))),
    end = seq(64, by = 64, length.out = length(unique(df$id)))
  )
  
  fit = stanHmodel1$sample(data = list(N = nrow(df), 
                                       tcf = df$x,
                                       phs = df$phs,
                                       rt = df$rt,
                                       conf = df$conf,
                                       S = length(unique(df$id)),
                                       S_id = df$id,
                                       starts = ranges$start,
                                       ends = ranges$end,
                                       age_z = unique(df$z_age),
                                       min_rt = unique(df$min_rt)),
                           refresh = 100,
                           iter_warmup = samples,
                           iter_sampling = samples,
                           parallel_chains = 4,
                           adapt_delta = 0.99,
                           max_treedepth = 12,
                           init = 0)
  
  
  
  divs = data.frame(fit$diagnostic_summary()) %>% select(num_divergent, num_max_treedepth) %>% 
    summarize(mean_div = mean(num_divergent),
              mean_tree = mean(num_max_treedepth))
  
  
  
  sim_means = as.numeric(parameters)[1:15]
  sim_taus = as.numeric(parameters)[16:30]
  
  age_coefs = as.numeric(parameters)[31:34]
  
  
  means = fit$summary(c("mus_phs","mus_rt",paste0("mus_conf[",1:4,"]"),"mu_cutzero","mu_cutone")) %>% 
    mutate(parameters = names(parameters)[1:15],simulated_parameters = sim_means)
  
  means %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  means$sim_n = parameters$sim_n
  means$mean_div = divs$mean_div
  means$mean_tree = divs$mean_tree
  means$simulated_model = parameters$simulated_model
  means$fitted_model = "model1"
  means$estimation_time = fit$time()$total
  
  taus = fit$summary(c("sigmas_phs","sigmas_rt","sigmas_conf"))%>% 
    mutate(parameters = names(parameters)[16:30],simulated_parameters = sim_taus)
  
  taus %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  taus$sim_n = parameters$sim_n
  taus$mean_div = divs$mean_div
  taus$mean_tree = divs$mean_tree
  taus$simulated_model = parameters$simulated_model
  taus$fitted_model = "model1"
  
  ages = fit$summary(c("mus_age"))%>% 
    mutate(parameters = names(parameters)[31:34],simulated_parameters = age_coefs)
  
  ages %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  ages$sim_n = parameters$sim_n
  ages$mean_div = divs$mean_div
  ages$mean_tree = divs$mean_tree
  ages$simulated_model = parameters$simulated_model
  ages$fitted_model = "model1"
  
  
  sim_subjectlevel = df %>% 
    select(
      int_phs_age, slopes_phs_age, guess, lapse,
      int_rt_age, slopes_rt, slopes1_rt, sigma_rt,ndt,
      int_conf_age,slopes_conf,slopes1_conf,prec_conf,cut0,cut1
    ) %>% 
    distinct() %>% 
    ungroup() %>% 
    mutate(prec_conf = exp(prec_conf),
           sigma_rt = exp(sigma_rt),
           subject = 1:parameters$n_sub) %>% 
    pivot_longer(-subject, values_to = "simulated_parameters", names_to = "parameters") %>% 
    mutate(parameters = recode(parameters,
                               "int_phs_age" = "a_phs",
                               "slopes_phs_age" = "b_phs",
                               "guess" = "g_phs",
                               "lapse" = "l_phs",
                               "int_rt_age" = "a_rt",
                               "slopes_rt" = "b_rt",
                               "slopes1_rt" = "b1_rt",
                               "sigma_rt" = "sigma_rt",
                               "ndt" = "ndt",
                               "int_conf_age" = "a_conf",
                               "slopes_conf" = "b_conf",
                               "slopes1_conf" = "b1_conf",
                               "prec_conf" = "phi_conf",
                               "cut0" = "cutzero",
                               "cut1" = "cutone"
    ))
  
  subjectparameters = c("a_phs","b_phs","g_phs","l_phs",
                        "a_rt","b_rt","b1_rt","sigma_rt", "ndt",
                        "a_conf","b_conf","b1_conf","phi_conf","cutzero","cutone")
  
  subjectlevel = fit$summary(subjectparameters) %>% 
    mutate(subject = as.numeric(sub(".*\\[(\\d+)\\].*", "\\1", variable)),
           parameters = str_remove(variable, "\\[.*\\]"),
    )
  
  
  subject_level = inner_join(subjectlevel,sim_subjectlevel,by=c("parameters","subject"))
  
  subject_level %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  subject_level$sim_n = parameters$sim_n
  subject_level$mean_div = divs$mean_div
  subject_level$mean_tree = divs$mean_tree
  subject_level$simulated_model = parameters$simulated_model
  subject_level$fitted_model = "model1"
  
  
  return(list(means, taus,ages,subject_level,fit))
  
}
fit_model_m2 = function(parameters,df, test = F){
  
  if(test){
    samples = 10
  }else{
    samples = 500
  }
  
  
  
  
  # first initiate stan model
  stanHmodel2 <- cmdstanr::cmdstan_model(here::here("analysis","simulations","stanmodels",'phs-hierarchical_m2_vec.stan')) #initiate model
  
  
  ranges <- data.frame(
    start = seq(1, by = 64, length.out = length(unique(df$id))),
    end = seq(64, by = 64, length.out = length(unique(df$id)))
  )
  
  fit = stanHmodel2$sample(data = list(N = nrow(df), 
                                       tcf = df$x,
                                       phs = df$phs,
                                       rt = df$rt,
                                       conf = df$conf,
                                       S = length(unique(df$id)),
                                       S_id = df$id,
                                       starts = ranges$start,
                                       ends = ranges$end,
                                       age_z = unique(df$z_age),
                                       min_rt = unique(df$min_rt)),
                           refresh = 100,
                           iter_warmup = samples,
                           iter_sampling = samples,
                           parallel_chains = 4,
                           adapt_delta = 0.99,
                           max_treedepth = 12,
                           init = 0)
  
  
  
  divs = data.frame(fit$diagnostic_summary()) %>% select(num_divergent, num_max_treedepth) %>% 
    summarize(mean_div = mean(num_divergent),
              mean_tree = mean(num_max_treedepth))
  
  
  
  sim_means = as.numeric(parameters)[1:15]
  sim_taus = as.numeric(parameters)[16:30]
  
  age_coefs = as.numeric(parameters)[31:34]
  
  
  means = fit$summary(c("mus_phs","mus_rt",paste0("mus_conf[",1:4,"]"),"mu_cutzero","mu_cutone")) %>% 
    mutate(parameters = names(parameters)[1:15],simulated_parameters = sim_means)
  
  means %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  means$sim_n = parameters$sim_n
  means$mean_div = divs$mean_div
  means$mean_tree = divs$mean_tree
  means$simulated_model = parameters$simulated_model
  means$fitted_model = "model2"
  means$estimation_time = fit$time()$total
  
  
  taus = fit$summary(c("sigmas_phs","sigmas_rt","sigmas_conf"))%>% 
    mutate(parameters = names(parameters)[16:30],simulated_parameters = sim_taus)
  
  taus %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  taus$sim_n = parameters$sim_n
  taus$mean_div = divs$mean_div
  taus$mean_tree = divs$mean_tree
  taus$simulated_model = parameters$simulated_model
  taus$fitted_model = "model2"
  
  
  ages = fit$summary(c("mus_age"))%>% 
    mutate(parameters = names(parameters)[31:34],simulated_parameters = age_coefs)
  
  ages %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  ages$sim_n = parameters$sim_n
  ages$mean_div = divs$mean_div
  ages$mean_tree = divs$mean_tree
  ages$simulated_model = parameters$simulated_model
  ages$fitted_model = "model2"
  
  
  sim_subjectlevel = df %>% 
    select(
      int_phs_age, slopes_phs_age, guess, lapse,
      int_rt_age, slopes_rt, slopes1_rt, sigma_rt,ndt,
      int_conf_age,slopes_conf,slopes1_conf,prec_conf,cut0,cut1
    ) %>% 
    distinct() %>% 
    ungroup() %>% 
    mutate(prec_conf = exp(prec_conf),
           sigma_rt = exp(sigma_rt),
           subject = 1:parameters$n_sub) %>% 
    pivot_longer(-subject, values_to = "simulated_parameters", names_to = "parameters") %>% 
    mutate(parameters = recode(parameters,
                               "int_phs_age" = "a_phs",
                               "slopes_phs_age" = "b_phs",
                               "guess" = "g_phs",
                               "lapse" = "l_phs",
                               "int_rt_age" = "a_rt",
                               "slopes_rt" = "b_rt",
                               "slopes1_rt" = "b1_rt",
                               "sigma_rt" = "sigma_rt",
                               "ndt" = "ndt",
                               "int_conf_age" = "a_conf",
                               "slopes_conf" = "b_conf",
                               "slopes1_conf" = "b1_conf",
                               "prec_conf" = "phi_conf",
                               "cut0" = "cutzero",
                               "cut1" = "cutone"
    ))
  
  subjectparameters = c("a_phs","b_phs","g_phs","l_phs",
                        "a_rt","b_rt","b1_rt","sigma_rt", "ndt",
                        "a_conf","b_conf","b1_conf","phi_conf","cutzero","cutone")
  
  subjectlevel = fit$summary(subjectparameters) %>% 
    mutate(subject = as.numeric(sub(".*\\[(\\d+)\\].*", "\\1", variable)),
           parameters = str_remove(variable, "\\[.*\\]"),
    )
  
  
  subject_level = inner_join(subjectlevel,sim_subjectlevel,by=c("parameters","subject"))
  
  subject_level %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  subject_level$sim_n = parameters$sim_n
  subject_level$mean_div = divs$mean_div
  subject_level$mean_tree = divs$mean_tree
  
  subject_level$simulated_model = parameters$simulated_model
  subject_level$fitted_model = "model2"
  
  
  return(list(means, taus,ages,subject_level,fit))
  
}


fit_model_m0 = function(parameters,df, test = F){
  
  if(test){
    samples = 10
  }else{
    samples = 500
  }
  
  
  # first initiate stan model
  stanHmodel1 <- cmdstanr::cmdstan_model(here::here("analysis","simulations","stanmodels",'phs-hierarchical_m0_vec.stan')) #initiate model
  
  ranges <- data.frame(
    start = seq(1, by = 64, length.out = length(unique(df$id))),
    end = seq(64, by = 64, length.out = length(unique(df$id)))
  )
  
  fit = stanHmodel1$sample(data = list(N = nrow(df), 
                                       tcf = df$x,
                                       phs = df$phs,
                                       S = length(unique(df$id)),
                                       S_id = df$id,
                                       starts = ranges$start,
                                       ends = ranges$end,
                                       age_z = unique(df$z_age),
                                       min_rt = unique(df$min_rt)),
                           refresh = 100,
                           iter_warmup = samples,
                           iter_sampling = samples,
                           parallel_chains = 4,
                           adapt_delta = 0.99,
                           max_treedepth = 12,
                           init = 0)
  
  
  divs = data.frame(fit$diagnostic_summary()) %>% select(num_divergent, num_max_treedepth) %>% 
    summarize(mean_div = mean(num_divergent),
              mean_tree = mean(num_max_treedepth))
  
  
  
  sim_means = as.numeric(parameters)[1:4]
  sim_taus = as.numeric(parameters)[18:21]
  age_coefs = as.numeric(parameters)[31:32]
  
  
  means = fit$summary(c("mus_phs")) %>% 
    mutate(parameters = names(parameters)[1:4],simulated_parameters = sim_means)
  
  means %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  
  means$sim_n = parameters$sim_n
  means$mean_div = divs$mean_div
  means$mean_tree = divs$mean_tree
  
  means$simulated_model = parameters$simulated_model
  means$fitted_model = "model0"
  means$estimation_time = fit$time()$total
  
  
  ages = fit$summary(c("mus_age"))%>% 
    mutate(parameters = names(parameters)[31:32],simulated_parameters = age_coefs)
  
  ages %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  ages$sim_n = parameters$sim_n
  ages$mean_div = divs$mean_div
  ages$mean_tree = divs$mean_tree
  
  ages$simulated_model = parameters$simulated_model
  ages$fitted_model = "model0"
  
  taus = fit$summary(c("sigmas_phs"))%>% 
    mutate(parameters = names(parameters)[18:21],simulated_parameters = sim_taus)
  
  taus %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  
  taus$sim_n = parameters$sim_n
  taus$mean_div = divs$mean_div
  taus$mean_tree = divs$mean_tree
  taus$simulated_model = parameters$simulated_model
  taus$fitted_model = "model0"
  
  
  sim_subjectlevel = df %>% 
    select(
      int_phs_age, slopes_phs_age, guess, lapse
    ) %>% 
    distinct() %>% 
    ungroup() %>% 
    mutate(
      subject = 1:parameters$n_sub) %>% 
    pivot_longer(-subject, values_to = "simulated_parameters", names_to = "parameters") %>% 
    mutate(parameters = recode(parameters,
                               "int_phs_age" = "a_phs",
                               "slopes_phs_age" = "b_phs",
                               "guess" = "g_phs",
                               "lapse" = "l_phs"
    ))
  
  subjectparameters = c("a_phs","b_phs","g_phs","l_phs")
  
  subjectlevel = fit$summary(subjectparameters) %>% 
    mutate(subject = as.numeric(sub(".*\\[(\\d+)\\].*", "\\1", variable)),
           parameters = str_remove(variable, "\\[.*\\]"),
    )
  
  
  subject_level = inner_join(subjectlevel,sim_subjectlevel,by=c("parameters","subject"))
  
  subject_level %>% ggplot(aes(x = simulated_parameters, y = mean, ymin = q5, ymax = q95))+
    geom_pointrange()+facet_wrap(~parameters,scales="free")+geom_abline()
  
  subject_level$sim_n = parameters$sim_n
  subject_level$mean_div = divs$mean_div
  subject_level$mean_tree = divs$mean_tree
  subject_level$simulated_model = parameters$simulated_model
  subject_level$fitted_model = "model0"
  
  
  
  return(list(means, taus,ages,subject_level,fit))
  
}

sim_data_m1 = function(parameters){
  
  n_trials = 64
  
  xs = seq(5,80,length.out = n_trials)
  #calculating desired covariance
  
  # correlation matrix
  rho = .5
  R = cor_mat(rho, parameters$tau_int_phs^2, parameters$tau_slope_phs^2)
  #means
  mu <- c(X = parameters$mu_int_phs, Y = parameters$mu_slope_phs)
  #random variables from the multivariate normal
  cor_data = data.frame(mvtnorm::rmvnorm(parameters$n_sub, mean = mu, sigma = R)) %>% 
    mutate(intercept = X, slopes = Y)
  
  #means
  #random variables from the multivariate normal
  
  int_g <- rnorm(parameters$n_sub, parameters$mu_int_g, parameters$tau_int_g)
  int_l <- rnorm(parameters$n_sub, parameters$mu_int_l, parameters$tau_int_l)
  
  int_rt <- rnorm(parameters$n_sub, parameters$mu_int_rt, parameters$tau_int_rt)
  slopes_rt <- rnorm(parameters$n_sub, parameters$mu_slopes_rt, parameters$tau_slopes_rt)
  sigma_rt <- rnorm(parameters$n_sub, parameters$mu_sigma_rt, parameters$tau_sigma_rt)
  int_ndt = rnorm(parameters$n_sub, parameters$mu_ndt_rt, parameters$tau_ndt_rt)
  
  slopes1_conf = rnorm(parameters$n_sub, parameters$mu_slopes1_conf, parameters$tau_slopes1_conf)
  slopes1_rt = rnorm(parameters$n_sub, parameters$mu_slopes1_rt, parameters$tau_slopes1_rt)
  
  # rest of the parameters - start off with a normal distribution and move to a probabilistic later
  #intercepts:
  int_conf = rnorm(parameters$n_sub,parameters$mu_int_conf,parameters$tau_int_conf)
  #slopes
  slopes_conf = rnorm(parameters$n_sub,parameters$mu_slopes_conf,parameters$tau_slopes_conf)
  #distribution
  prec_conf = rnorm(parameters$n_sub,parameters$mu_prec_conf,parameters$tau_prec_conf)
  # guess and lapse
  cut0 = rnorm(parameters$n_sub,parameters$mu_cut0,parameters$tau_cut0)
  cut1 = rnorm(parameters$n_sub,parameters$mu_cut1,parameters$tau_cut1)
  
  
  df <- cor_data %>%  
    mutate(int_phs = intercept, slopes_phs = slopes,
           guess = inv_logit_scaled(int_g)/2, lapse = inv_logit_scaled(int_l)/2,
           int_rt = int_rt, slopes_rt = slopes_rt, slopes1_rt = slopes1_rt, sigma_rt = sigma_rt, int_ndt = int_ndt,
           int_conf = int_conf, slopes_conf = slopes_conf, slopes1_conf = slopes1_conf, prec_conf = prec_conf,
           cut0 = cut0, cut1 = cut1) %>% 
    mutate(id = 1:parameters$n_sub, x = list(xs),
           age = seq(20,80,length.out = parameters$n_sub),
           z_age = scale(age)[,1]) %>% #adding age
    mutate(int_phs_age = exp(int_phs+parameters$age_int_coeff*z_age),
           slopes_phs_age = exp(slopes_phs+parameters$age_slopes_coeff*z_age),
           int_rt_age = int_rt+parameters$age_rt_coeff*z_age,
           int_conf_age = int_conf+parameters$age_conf_coeff*z_age) %>% 
    unnest(x) %>% 
    rowwise() %>% 
    mutate(p = prob_func(x,int_phs_age,slopes_phs_age,guess,lapse),
           rtP = int_rt_age+(slopes_rt*(entropy(p))+(slopes1_rt*x)),
           cP = inv_logit_scaled(int_conf_age+(slopes_conf*(entropy(p))+(slopes1_conf*x))),
           phs = rbinom(1,1,p),
           rt = rlnorm(n(),rtP,exp(sigma_rt)),
           conf = rordbeta(n(),(cP), exp(prec_conf), cutpoints = c(cut0,cut1))
    ) %>% 
    # sort out rt
    group_by(id) %>% 
    mutate(min_rt = min(rt)) %>% 
    ungroup(id) %>% 
    mutate(ndt = (0.2+inv_logit_scaled(int_ndt)*(min_rt-0.2)),
           rt = rt + ndt,# add NDT
           rt = ifelse(rt > 10, 10, rt)
    )
  
  return(df)
}
sim_data_m2 = function(parameters){
  
  n_trials = 64
  
  xs = seq(5,80,length.out = n_trials)
  #calculating desired covariance
  
  # correlation matrix
  rho = .5
  R = cor_mat(rho, parameters$tau_int_phs^2, parameters$tau_slope_phs^2)
  #means
  mu <- c(X = parameters$mu_int_phs, Y = parameters$mu_slope_phs)
  #random variables from the multivariate normal
  cor_data = data.frame(mvtnorm::rmvnorm(parameters$n_sub, mean = mu, sigma = R)) %>% 
    mutate(intercept = X, slopes = Y)
  
  #means
  #random variables from the multivariate normal
  
  int_g <- rnorm(parameters$n_sub, parameters$mu_int_g, parameters$tau_int_g)
  int_l <- rnorm(parameters$n_sub, parameters$mu_int_l, parameters$tau_int_l)
  
  int_rt <- rnorm(parameters$n_sub, parameters$mu_int_rt, parameters$tau_int_rt)
  slopes_rt <- rnorm(parameters$n_sub, parameters$mu_slopes_rt, parameters$tau_slopes_rt)
  sigma_rt <- rnorm(parameters$n_sub, parameters$mu_sigma_rt, parameters$tau_sigma_rt)
  int_ndt = rnorm(parameters$n_sub, parameters$mu_ndt_rt, parameters$tau_ndt_rt)
  
  slopes1_conf = rnorm(parameters$n_sub, parameters$mu_slopes1_conf, parameters$tau_slopes1_conf)
  slopes1_rt = rnorm(parameters$n_sub, parameters$mu_slopes1_rt, parameters$tau_slopes1_rt)
  
  # rest of the parameters - start off with a normal distribution and move to a probabilistic later
  #intercepts:
  int_conf = rnorm(parameters$n_sub,parameters$mu_int_conf,parameters$tau_int_conf)
  #slopes
  slopes_conf = rnorm(parameters$n_sub,parameters$mu_slopes_conf,parameters$tau_slopes_conf)
  #distribution
  prec_conf = rnorm(parameters$n_sub,parameters$mu_prec_conf,parameters$tau_prec_conf)
  # guess and lapse
  cut0 = rnorm(parameters$n_sub,parameters$mu_cut0,parameters$tau_cut0)
  cut1 = rnorm(parameters$n_sub,parameters$mu_cut1,parameters$tau_cut1)
  
  
  df <- cor_data %>%  
    mutate(int_phs = intercept, slopes_phs = slopes,
           guess = inv_logit_scaled(int_g)/2, lapse = inv_logit_scaled(int_l)/2,
           int_rt = int_rt, slopes_rt = slopes_rt, slopes1_rt = slopes1_rt, sigma_rt = sigma_rt, int_ndt = int_ndt,
           int_conf = int_conf, slopes_conf = slopes_conf, slopes1_conf = slopes1_conf, prec_conf = prec_conf,
           cut0 = cut0, cut1 = cut1) %>% 
    mutate(id = 1:parameters$n_sub, x = list(xs),
           age = seq(20,80,length.out = parameters$n_sub),
           z_age = scale(age)[,1]) %>% #adding age
    mutate(int_phs_age = exp(int_phs+parameters$age_int_coeff*z_age),
           slopes_phs_age = exp(slopes_phs+parameters$age_slopes_coeff*z_age),
           int_rt_age = int_rt+parameters$age_rt_coeff*z_age,
           int_conf_age = int_conf+parameters$age_conf_coeff*z_age) %>% 
    unnest(x) %>% 
    rowwise() %>% 
    mutate(p = prob_func(x,int_phs_age,slopes_phs_age,guess,lapse),
           rtP = int_rt_age+(slopes_rt*((p))+(slopes1_rt*x)),
           cP = inv_logit_scaled(int_conf_age+(slopes_conf*((p))+(slopes1_conf*x))),
           phs = rbinom(1,1,p),
           rt = rlnorm(n(),rtP,exp(sigma_rt)),
           conf = rordbeta(n(),(cP), exp(prec_conf), cutpoints = c(cut0,cut1))
    ) %>% 
    # sort out rt
    group_by(id) %>% 
    mutate(min_rt = min(rt)) %>% 
    ungroup(id) %>% 
    mutate(ndt = (0.2+inv_logit_scaled(int_ndt)*(min_rt-0.2)),
           rt = rt + ndt,# add NDT
           rt = ifelse(rt > 10, 10, rt)
    )
  
  return(df)
}




fit_pr = function(parameters){
  
 if(parameters$simulated_model == "model1"){
   df = sim_data_m1(parameters)
 }else if(parameters$simulated_model == "model2"){
   df = sim_data_m2(parameters)
 }
  
  seed = rnorm(1,0,10000)
  
  
  if(sum(df$rt == 10) / nrow(df) > 0.02){
    return("Error")
    }
  
  
  # df %>% ggplot(aes(x = x, y = conf))+geom_point()+facet_wrap(~id)
  # df %>% ggplot(aes(x = x, y = rt))+geom_point()+facet_wrap(~id)+scale_y_continuous(limits = c(0,5))
  # df %>% ggplot(aes(x = x, y = p))+geom_point()+facet_wrap(~id)

  
  model2 = fit_model_m2(parameters,df, test = F)
  model1 = fit_model_m1(parameters,df, test = F)
  model0 = fit_model_m0(parameters,df, test = F)
  
  model2_loo_bin = model2[[5]]$loo("ll_bin")  
  model1_loo_bin = model1[[5]]$loo("ll_bin")
  model0_loo_bin = model0[[5]]$loo("ll_bin")
  
  loo_binary = data.frame(loo::loo_compare(list(model0 = model0_loo_bin,
                                                model1 = model1_loo_bin,
                                                model2 = model2_loo_bin))) %>%   
    rownames_to_column()%>% 
    rename(model = rowname)%>% arrange(model) %>% 
    mutate(simulated_model = parameters$simulated_model)
  
  
  loo_binary_full = data.frame(loo::loo_compare(list(model1 = model1_loo_bin,
                                                     model2 = model2_loo_bin))) %>%   
    rownames_to_column()%>% 
    rename(model = rowname)%>% arrange(model) %>% 
    mutate(simulated_model = parameters$simulated_model)
    
  
  
  diagnostics_bin = data.frame(mean_div = c(max(model0[[1]]$mean_div),max(model1[[1]]$mean_div), max(model2[[1]]$mean_div)),
                           mean_tree = c(max(model0[[1]]$mean_tree),max(model1[[1]]$mean_tree),max(model2[[1]]$mean_tree)),
                           pareto_k_over07 = c(sum(model0_loo_bin$diagnostics$pareto_k > 0.7),
                                               sum(model1_loo_bin$diagnostics$pareto_k > 0.7),
                                               sum(model2_loo_bin$diagnostics$pareto_k > 0.7)),
                           model = c("model0","model1","model2"),
                           idx = seed,
                           sim_n = parameters$sim_n)

  
  
  
  bin_loo = inner_join(loo_binary,diagnostics_bin)
  
  bin_loo_full = inner_join(loo_binary_full,diagnostics_bin)
  
  model2_loo_full = model2[[5]]$loo("log_lik")  
  model1_loo_full = model1[[5]]$loo("log_lik")
  
  loo_full = data.frame(loo::loo_compare(list(model1 = model1_loo_full,
                                              model2 = model2_loo_full))) %>%   
    rownames_to_column()%>% 
    rename(model = rowname)%>% 
    arrange(model) %>% 
    mutate(simulated_model = parameters$simulated_model)
    
  
  
  
  diagnostics_full = data.frame(mean_div = c(max(model1[[1]]$mean_div), max(model2[[1]]$mean_div)),
                           mean_tree = c(max(model1[[1]]$mean_tree),max(model2[[1]]$mean_tree)),
                           pareto_k_over07 = c(sum(model1_loo_full$diagnostics$pareto_k > 0.7),
                                               sum(model2_loo_full$diagnostics$pareto_k > 0.7)),
                           model = c("model1","model2"), idx = seed,
                           sim_n = parameters$sim_n)

  
  full_loo = inner_join(loo_full,diagnostics_full)
  
  model0[[5]] = NULL
  model1[[5]] = NULL
  model2[[5]] = NULL
  
  df = df %>% mutate(sim_n = parameters$sim_n)
  
  return(list(full_loo,bin_loo,bin_loo_full,model0,model1,model2,df))
}
