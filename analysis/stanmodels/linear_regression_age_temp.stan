data {
  int<lower=1> N;          // number of observations
  vector[N] age;             // variable 1
  vector[N] y;             // variable 2
}

parameters {
  vector[2] beta;            // means of x and y
  real<lower=0> sigma; // standard deviations of x and y
}

model {
  // Priors (you can make these more informative if needed)
  beta[1] ~ normal(30, 20);
  beta[2] ~ normal(0, 5);
  
  sigma ~ normal(3, 10);

  y ~ normal(beta[1] + beta[2] * age, sigma);
  
}
