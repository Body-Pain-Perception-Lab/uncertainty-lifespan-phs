rordbeta <- function(n=100,
                     mu=0.5,
                     phi=1,
                     cutpoints=c(-1,1)) {
  
  if(!all(mu>0 & mu<1) ) {
    
    stop("Please pass a numeric value for mu that is between 0 and 1.")
    
  }
  
  if(!all(phi>0)) {
    
    stop("Please pass a numeric value for phi that is greater than 0.")
    
  }
  
  if(!(length(mu) %in% c(1,n))) {
    
    stop("Please pass a vector for mu that is either length 1 or length N.")
    
  }
  
  if(!(length(phi) %in% c(1,n))) {
    
    stop("Please pass a vector for phi that is either length 1 or length N.")
    
  }
  
  mu_ql <- qlogis(mu)
  
  if(length(mu_ql)==1) {
    mu_ql <- rep(mu_ql, n)
  }
  
  # probabilities for three possible categories (0, proportion, 1)
  low <- 1-plogis(mu_ql - cutpoints[1])
  middle <- plogis(mu_ql - cutpoints[1]) - plogis(mu_ql - cutpoints[2])
  high <- plogis(mu_ql - cutpoints[2])
  
  # we'll assume the same eta was used to generate outcomes
  
  out_beta <- rbeta(n = n,mu * phi, (1 - mu) * phi)
  
  # now determine which one we get for each observation
  outcomes <- sapply(1:n, function(i) {
    
    sample(1:3,size=1,prob=c(low[i],middle[i],high[i]))
    
  })
  
  # now combine binary (0/1) with proportion (beta)
  
  final_out <- sapply(1:n,function(i) {
    if(outcomes[i]==1) {
      return(0)
    } else if(outcomes[i]==2) {
      return(out_beta[i])
    } else {
      return(1)
    }
  })
  
  
  return(final_out)
  
}