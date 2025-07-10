// ordered beta function
functions{
  
  real ord_beta_reg_lpdf(real y, real mu, real phi, real cutzero, real cutone) {

    vector[2] thresh;
    thresh[1] = cutzero;
    thresh[2] = cutzero + exp(cutone);

  if(y==0) {
      return log1m_inv_logit(mu - thresh[1]);
    } else if(y==1) {
      return log_inv_logit(mu  - thresh[2]);
    } else {
      return log_diff_exp(log_inv_logit(mu   - thresh[1]), log_inv_logit(mu - thresh[2])) +
                beta_lpdf(y|exp(log_inv_logit(mu) + log(phi)),exp(log1m_inv_logit(mu) + log(phi)));
    }
  }
  
  real induced_dirichlet_lpdf(real nocut, vector alpha, real phi, int cutnum, real cut1, real cut2) {
    int K = num_elements(alpha);
    vector[K-1] c = [cut1, cut1 + exp(cut2)]';
    vector[K - 1] sigma = inv_logit(phi - c);
    vector[K] p;
    matrix[K, K] J = rep_matrix(0, K, K);

    if(cutnum==1) {

    // Induced ordinal probabilities
    p[1] = 1 - sigma[1];
    for (k in 2:(K - 1))
      p[k] = sigma[k - 1] - sigma[k];
    p[K] = sigma[K - 1];

    // Baseline column of Jacobian
    for (k in 1:K) J[k, 1] = 1;

    // Diagonal entries of Jacobian
    for (k in 2:K) {
      real rho = sigma[k - 1] * (1 - sigma[k - 1]);
      J[k, k] = - rho;
      J[k - 1, k] = rho;
    }

    // divide in half for the two cutpoints

    // don't forget the ordered transformation

      return   dirichlet_lpdf(p | alpha)
           + log_determinant(J) + cut2;
    } else {
      return(0);
    }
  }
}


data {
  int<lower=1> N;          // number of observations
  vector[N] age;             // variable 1
  vector[N] VAS;             // variable 1
}

parameters {
  vector[2] beta;            // means of x and y
  real c0;
  real c1;
  real <lower=0> prec;
  
}

model {
  // Priors (you can make these more informative if needed)
  beta[1] ~ normal(0, 3);
  beta[2] ~ normal(0, 3);
  prec ~ normal(2, 5);
  
  c0 ~ induced_dirichlet([1,1,1]', 0, 1, c0, c1);
  c1 ~ induced_dirichlet([1,1,1]', 0, 2, c0, c1);
  
  for(n in 1:N){
   target += ord_beta_reg_lpdf(VAS[n] | beta[1] + beta[2] * age[n], prec, c0,c1); 
  }
  
}
