data {
  int<lower=1> N;                    // number of observations
  int<lower=1> S;                    // number of subjects
  array[N] int<lower=1, upper=S> S_id;  // subject IDs
  vector[N] catch;                   // predictor
  array[N] int<lower=0, upper=1> y;        // binary response
}

parameters {
  vector[2] gm;                    // fixed effects: intercept and catch
  vector[S] intercept_dif;             // random intercepts
  vector[S] slope_dif;                 // random slopes for catch
  real<lower=0> sigma_intercept;     // std dev of random intercepts
  real<lower=0> sigma_slope;         // std dev of random slopes
}

model {
  // Priors
  gm ~ normal(0, 10);
  
  sigma_intercept ~ normal(0, 5);
  sigma_slope ~ normal(0, 5);
  
  intercept_dif ~ normal(0, 1);
  slope_dif ~ normal(0, 1);

  // Likelihood
  for (n in 1:N) {
    real eta = gm[1] + sigma_intercept * intercept_dif[S_id[n]]
                         + (gm[2] + sigma_slope * slope_dif[S_id[n]]) * catch[n];
    y[n] ~ bernoulli_logit(eta);
  }
}
