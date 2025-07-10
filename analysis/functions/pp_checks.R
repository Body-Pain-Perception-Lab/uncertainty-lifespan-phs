pp_checks = function(x,a_phs,b_phs,a_rt,b_rt,sigma_rt,a_conf,b_conf,prec_conf){
  
  p = 0.5+0.5*erf((x-a_phs)/(sqrt(2)*b_phs))
  rtP = exp(a_rt+b_rt*p)
  cP = a_conf+b_conf*p
  cP = inv_logit_scaled(cP)
  
  return(data.frame(x = x, p = p, rtP = rtP, cP = cP))
}