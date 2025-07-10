data {
  int<lower=1> N;          // number of observations
  vector[N] x;             // variable 1
  vector[N] y;             // variable 2
}

parameters {
  vector[2] mu;            // means of x and y
  vector<lower=0>[2] sigma; // standard deviations of x and y

  real<lower=0, upper=1> rho_raw;         // raw correlation on [0, 1]

}

transformed parameters{
  real<lower=-1, upper=1> rho;            // correlation on [-1, 1]
  rho = 2 * rho_raw - 1;
}

model {
  // Priors (you can make these more informative if needed)
  mu[1] ~ normal(0, 5);
  mu[2] ~ normal(10, 10);
  
  sigma[1] ~ normal(1, 3);
  sigma[2] ~ normal(10, 5);
  rho_raw ~ beta_proportion(0.5, 10);

  // Define covariance matrix
  matrix[2,2] cov;
  cov[1,1] = square(sigma[1]);
  cov[2,2] = square(sigma[2]);
  cov[1,2] = rho * sigma[1] * sigma[2];
  cov[2,1] = cov[1,2];

  // Combine x and y into a 2D vector for each observation
  for (n in 1:N) {
    vector[2] xy;
    xy[1] = x[n];
    xy[2] = y[n];
    xy ~ multi_normal(mu, cov);
  }
}
