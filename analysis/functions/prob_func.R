prob_func = function(x,a,b,g,l){
  #a = intercept, b = slope (lower limit = 0), x = data
  #l = lapse rate[0 - 0.5], g = guess rate[0 - 0.5]
  
  prob_func = g + (1-g-l)*(brms::inv_logit_scaled(b*(x-a)))
  #prob_func = 0.5+0.5*erf((x-a)/(sqrt(2)*b))
  
  return(prob_func)
}