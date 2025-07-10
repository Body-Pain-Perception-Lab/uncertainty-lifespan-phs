cor_mat = function(rho, varX, varY){
  
  cov = rho*sqrt(varX*varY)
  
  # correlation matrix
  cor_mat <- matrix(c(varX, cov,
                cov, varY), 
              nrow = 2, ncol = 2, 
              byrow = TRUE)
  
  return(cor_mat)
}