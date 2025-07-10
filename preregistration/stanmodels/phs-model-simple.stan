//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
//
// Learn more about model development with Stan at:
//
//    http://mc-stan.org/users/interfaces/rstan.html
//    https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started
//

// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N;
  
  // one way of doing it
  vector[N] tcf; // contrast vector
  array[N] int y;
}

// The parameters accepted by the models.
parameters {
  real a_phs;
  real<lower=0> b_phs;
}

// logistic regression model for PHS
// reaction time model based off of PHS prob
transformed parameters {
  vector[N] p;
  p = 0.5+0.5*erf((tcf-a_phs)/(sqrt(2)*b_phs)); //this function already does the inv_logit tranformation
}

// The model to be estimated. We model the output
// 'y' to be normally distributed with mean 'mu'
// and standard deviation 'sigma'.
model {
  a_phs ~ normal(0,100);
  b_phs ~ normal(0,30);
  
  y ~ bernoulli(p);
}

