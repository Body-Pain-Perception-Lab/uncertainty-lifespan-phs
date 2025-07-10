entropy = function(p){
  entropy = -((p)*log(p)+(1-p)*log(1-p))
  
  return(entropy)
}