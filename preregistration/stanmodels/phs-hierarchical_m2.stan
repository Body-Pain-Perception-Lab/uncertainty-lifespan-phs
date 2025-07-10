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

// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N; //number of trials
  int S; //number of subjects
  array[N] int S_id; //subject identifier
  
  array[N] int phs; //input - phs
  vector[N] tcf; //input - contrast
  vector[N] rt; //input - rt
  vector[N] conf; //input - confidence
  vector[S] age_z; //normliased age of subject
  vector[S] min_rt; //minimum response time for each participant
}

// The parameters accepted by the model.
// subject level with normal distribution around the parameters
parameters {
  // phs
  vector[4] mus_phs;
  vector<lower=0>[4] sigmas_phs;
  matrix[4,S] difs_phs;
  
  // rt
  vector[5] mus_rt;
  vector<lower=0>[5] sigmas_rt;
  matrix[5,S] difs_rt;
  
  // confidence
  vector[6] mus_conf;
  vector<lower=0>[6] sigmas_conf;
  matrix[6,S] difs_conf;
  
  // age
  vector[4] mus_age;
}

//transformed parameters for the model
// check that this is correct with Jesper
transformed parameters {
  vector[N] p;
  vector[N] rtP;
  vector[N] cP;
  
  // intercepts and slopes for each subject
  // phs
  vector[S] a_phs = exp(to_vector(mus_phs[1]+(difs_phs[1,])*sigmas_phs[1])+mus_age[1].*age_z);
  vector[S] b_phs = exp(to_vector(mus_phs[2]+(difs_phs[2,])*sigmas_phs[2])+mus_age[2].*age_z);
  vector[S] g_phs = to_vector(inv_logit(mus_phs[3]+(difs_phs[3,])*sigmas_phs[3])/2);
  vector[S] l_phs = to_vector(inv_logit(mus_phs[4]+(difs_phs[4,])*sigmas_phs[4])/2);
  // rt
  vector[S] a_rt = to_vector(mus_rt[1]+(difs_rt[1,])*sigmas_rt[1])+mus_age[3].*age_z;
  vector[S] b_rt = to_vector(mus_rt[2]+(difs_rt[2,])*sigmas_rt[2]);
  vector[S] b1_rt = to_vector(mus_rt[3]+(difs_rt[3,])*sigmas_rt[3]);
  vector[S] sigma_rt = to_vector(exp(mus_rt[4]+(difs_rt[4,])*sigmas_rt[4]));
  vector[S] ndt_uc = to_vector(mus_rt[5]+(difs_rt[5,])*sigmas_rt[5]); //non-decision time, unconstrained
  vector[S] ndt = 0.3+inv_logit(ndt_uc).*(min_rt-0.3); //constraining ndt
  // confidence
  vector[S] a_conf = to_vector(mus_conf[1]+(difs_conf[1,])*sigmas_conf[1])+mus_age[4].*age_z;
  vector[S] b_conf = to_vector(mus_conf[2]+(difs_conf[2,])*sigmas_conf[2]);
  vector[S] b1_conf = to_vector(mus_conf[3]+(difs_conf[3,])*sigmas_conf[3]);
  vector[S] phi_conf = to_vector(exp(mus_conf[4]+(difs_conf[4,])*sigmas_conf[4]));
  vector[S] c0_conf = to_vector(mus_conf[5]+(difs_conf[5,])*sigmas_conf[5]);
  vector[S] c1_conf = to_vector(mus_conf[6]+(difs_conf[6,])*sigmas_conf[6]);
  
  // logistic function for each subject
  for (n in 1:N){
    p[n] = g_phs[S_id[n]]+(1-g_phs[S_id[n]]-l_phs[S_id[n]])*(inv_logit(b_phs[S_id[n]]*(tcf[n]-a_phs[S_id[n]]))); //log_probit function
    rtP[n] = a_rt[S_id[n]]+(b_rt[S_id[n]]*p[n])+(b1_rt[S_id[n]]*tcf[n]);
    cP[n] = a_conf[S_id[n]]+(b_conf[S_id[n]]*p[n])+(b1_conf[S_id[n]]*tcf[n]);
    }
}

// The model to be estimated. 
model {
  // phs priors
  mus_phs[1] ~ normal(4,.5); //mu
  sigmas_phs[1] ~ normal(1,.5); 

  mus_phs[2] ~ normal(-2,1.5); //beta
  sigmas_phs[2] ~ normal(0,1);

  mus_phs[3] ~ normal(-5,1); //guess
  sigmas_phs[3] ~ normal(0,1);

  mus_phs[4] ~ normal(0,1); //lapse
  sigmas_phs[4] ~ normal(0,1);

  to_vector(difs_phs) ~ std_normal(); //subject differentials
  
  // rt priors
  mus_rt[1] ~ normal(.3,.5); //mu
  sigmas_rt[1] ~ normal(1,1);
  
  mus_rt[2] ~ normal(2.5,1); //beta phs
  sigmas_rt[2] ~ normal(1,2);
  
  mus_rt[3] ~ normal(0,1); //beta tcf
  sigmas_rt[3] ~ normal(1,2);
  
  mus_rt[4] ~ normal(-1,0.5); //sigma
  sigmas_rt[4] ~ normal(.5,1);
  
  mus_rt[5] ~ normal(.2,.3); //non-decision time
  sigmas_rt[5] ~ normal(0,1);
  
  to_vector(difs_rt) ~ std_normal();
  
  // conf priors
  mus_conf[1] ~ normal(.9,.20); //mu
  sigmas_conf[1] ~ normal(.5,1.5);
  
  mus_conf[2] ~ normal(-2,1); //beta
  sigmas_conf[2] ~ normal(0,1);
  
  mus_conf[3] ~ normal(0,1); //beta tcf
  sigmas_conf[3] ~ normal(0,1);
  
  mus_conf[4] ~ normal(3,0.5); //phi
  sigmas_conf[4] ~ normal(0,1);
  
  mus_conf[5] ~ normal(-4,.25); //cut0
  sigmas_conf[5] ~ normal(0,1);
  
  mus_conf[6] ~ normal(2,.25); //cut1
  sigmas_conf[6] ~ normal(0,1);
  
  to_vector(difs_conf) ~ std_normal();
  
  // age priors
  mus_age ~ normal(0,0.3);
  
  //cut points for each participant
  for(s in 1:S){
    c0_conf[s] ~ induced_dirichlet([1,1,1]', 0, 1, c0_conf[s], c1_conf[s]);
    c1_conf[s] ~ induced_dirichlet([1,1,1]', 0, 2, c0_conf[s], c1_conf[s]);
  }
  
  // estimating phs and rt
  for(n in 1:N){
    phs[n] ~ bernoulli(p[n]);
    target += lognormal_lpdf(rt[n]-ndt[S_id[n]]|rtP[n], sigma_rt[S_id[n]]);
    conf[n] ~ ord_beta_reg(cP[n], phi_conf[S_id[n]], c0_conf[S_id[n]], c1_conf[S_id[n]]);
  }
}

generated quantities{
  // log likelihoods
  vector[N] ll_bin;
  vector[N] ll_rt;
  vector[N] ll_conf;
  
  vector[N] log_lik;
  
  for(n in 1:N){
    ll_bin[n] = bernoulli_lpmf(phs[n]|p[n]);
    ll_rt[n] = lognormal_lpdf(rt[n]-ndt[S_id[n]]|rtP[n], sigma_rt[S_id[n]]);
    ll_conf[n] = ord_beta_reg_lpdf(conf[n]|cP[n], phi_conf[S_id[n]], c0_conf[S_id[n]], c1_conf[S_id[n]]);
    
    log_lik[n] = ll_bin[n]+ll_rt[n]+ll_conf[n];
  }
}
