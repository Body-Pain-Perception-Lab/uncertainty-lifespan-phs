model1_sim = function(x,s,params1,param2,params3){
  # function with input x - an array by length(N)
  # params are data-frames with specific parameters associated with models used to simulate data
  # for the joint model
  
  # s = number of subjects
  
  # params 1 = logisitic probability 
  # params 2 = normal distribution
  # params 3 = beta probability distribution

  #phs - logistic
  p = 0.5+0.5*erf((x-params1$a)/(sqrt(2)*params1$b))
  # linear increasing rt
  rtP = params2$a+params2$b*p;
  # linear decreasing confidence
  cP = params3$a+params3$b*p;
    
    
  # final outputs
  phs = rbinom(N,1,p) #binomial
  rt = rnorm(N,rtP,params2$sigma) #response time - log norm
  rt = exp(rt)
  conf = rprop(N,params3$prec,brms::inv_logit_scaled(cP))
  
  #rtP = p*(1-p)
  #incrP = a1+b1*rtP #decreasing response time from threshold
  
  return(data.frame(x = x, p = p, rtP = rtP, cP = cP, phs = phs, rt = rt, conf = conf))
}