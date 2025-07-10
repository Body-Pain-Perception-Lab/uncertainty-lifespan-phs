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

functions {
  //entropy function
  vector entropy_vec(vector p) {
    return(-(p.*log(p)+(1-p).*log(1-p)));
  }

  real entropy(real p) {
    return(-(p.*log(p)+(1-p).*log(1-p)));
  }
  
  // ordered beta function
  real ord_beta_reg_lpdf(real y, real mu, real phi, real cutzero, real cutone) {

    vector[2] thresh;
    thresh[1] = cutzero;
    thresh[2] = cutzero + exp(cutone);

  if(y==0) {
      return log1m_inv_logit(mu - thresh[1]);
    } else if(y==1) {
      return log_inv_logit(mu  - thresh[2]);
    } else {
      return log_diff_exp(log_inv_logit(mu - thresh[1]), log_inv_logit(mu - thresh[2])) +
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

// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N; //number of trials

  array[N] int phs; //input - phs
  vector[N] tcf; //input - contrast
  vector[N] rt; //input - rt
  vector[N] conf; //input - confidence
  real min_rt; //minimum RT of given participant

  
}

// The parameters accepted by the model.
// subject level with normal distribution around the parameters
parameters {
  // phs
  vector[4] mus_phs;

  
  // rt
  vector[5] mus_rt;

  // confidence
  vector[6] mus_conf;

}

//transformed parameters for the model
// check that this is correct with Jesper
transformed parameters {

  // intercepts and slopes for each subject
  // phs
  real a_phs = exp(mus_phs[1]);
  real b_phs = exp(mus_phs[2]);
  real g_phs = (inv_logit(mus_phs[3]));
  real l_phs = (inv_logit(mus_phs[4]));
  // rt
  real a_rt = mus_rt[1];
  real b_rt = mus_rt[2]; //by phs
  real b1_rt = mus_rt[3]; //by tcf
  real sigma_rt = exp(mus_rt[4]);
  real ndt_uc = mus_rt[5]; //non-decision time
  real ndt = 0.2+inv_logit(ndt_uc).*(min_rt-0.2); //constraining ndt
  // confidence
  real a_conf = (mus_conf[1]);
  real b_conf = (mus_conf[2]);
  real b1_conf = (mus_conf[3]);
  real phi_conf = exp(mus_conf[4]);
  real c0_conf = mus_conf[5];
  real c1_conf = mus_conf[6];
  
}

// The model to be estimated. 
model {
  vector[N] p;

  // phs priors
  mus_phs[1] ~ normal(4,.5); //mu


  mus_phs[2] ~ normal(-2,1.5); //beta

  mus_phs[3] ~ normal(-5,1); //guess

  mus_phs[4] ~ normal(0,1); //lapse


  // rt priors
  mus_rt[1] ~ normal(.3,.5); //mu

  mus_rt[2] ~ normal(2.5,1); //beta phs

  mus_rt[3] ~ normal(0,1); //beta tcf

  mus_rt[4] ~ normal(.5,.5); //sigma

  mus_rt[5] ~ normal(-2,1); //non-decision time


  // conf priors
  mus_conf[1] ~ normal(.9,.20); //mu

  mus_conf[2] ~ normal(-2,1); //beta phs

  mus_conf[3] ~ normal(0,1); //beta tcf

  mus_conf[4] ~ normal(3,0.5); //phi

  mus_conf[5] ~ normal(-4,.25); //cut0

  mus_conf[6] ~ normal(2,.25); //cut1

  

    c0_conf ~ induced_dirichlet([1,1,1]', 0, 1, c0_conf, c1_conf);
    c1_conf ~ induced_dirichlet([1,1,1]', 0, 2, c0_conf, c1_conf);

    p = g_phs+(1-g_phs-l_phs)*(inv_logit(b_phs*(tcf-a_phs))); //log_probit function
    
    phs ~ bernoulli(p);
    
    target += lognormal_lpdf(rt - ndt| a_rt+(b_rt*entropy_vec(p))+(b1_rt*tcf), sigma_rt);

  // estimating phs and rt
  for(n in 1:N){
      conf[n] ~ ord_beta_reg(a_conf+(b_conf*entropy(p[n]))+(b1_conf*tcf[n]), phi_conf, c0_conf, c1_conf);

  }
}

generated quantities{
  // log likelihoods
  vector[N] ll_bin;
  vector[N] ll_rt;
  vector[N] ll_conf;
  vector[N] log_lik;
  vector[N] p_gq;



  real  mu_cutzero = mus_conf[5];
  real  mu_cutone = mus_conf[5] + exp(mus_conf[6]);

  real  cutzero = c0_conf;
  real  cutone = c0_conf + exp(c1_conf);

  for(n in 1:N){
    p_gq[n] = g_phs+(1-g_phs-l_phs)*(inv_logit(b_phs*(tcf[n]-a_phs))); //log_probit function

    ll_bin[n] = bernoulli_lpmf(phs[n]|p_gq[n]);

    ll_rt[n] = lognormal_lpdf(rt[n]-ndt|a_rt+(b_rt*entropy(p_gq[n]))+(b1_rt*tcf[n]), sigma_rt);

    ll_conf[n] = ord_beta_reg_lpdf(conf[n]|a_conf+(b_conf*entropy(p_gq[n]))+(b1_conf*tcf[n]), phi_conf, c0_conf, c1_conf);

    log_lik[n] = ll_bin[n]+ll_rt[n]+ll_conf[n];
  }
}
