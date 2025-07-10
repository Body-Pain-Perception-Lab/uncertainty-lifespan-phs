data {
  int<lower=1> N;          // number of observations
  vector[N] age;             // variable 1
  array[N] int y;             // variable 2
}

parameters {
  vector[2] beta;            // means of x and y
}

model {
  // Priors (you can make these more informative if needed)
  beta[1] ~ normal(0, 3);
  beta[2] ~ normal(0, 3);
  

  y ~ bernoulli_logit(beta[1] + beta[2] * age);
  
}
