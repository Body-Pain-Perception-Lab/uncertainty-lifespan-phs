

functions {
  //entropy function
  vector entropy_vec(vector p) {
    return(-(p.*log(p)+(1-p).*log(1-p)));
  }

  real entropy(real p) {
    return(-(p.*log(p)+(1-p).*log(1-p)));
  }
  
}

// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N; //number of trials
  int S; //number of subjects
  array[N] int S_id; //subject identifier
  
  array[N] int phs; //input - phs
  vector[N] tcf; //input - contrast
  vector[S] age_z; //age input - between subjects (scaled)

  
  array[S] int starts;
  array[S] int ends;
  
  
}

// The parameters accepted by the model.
// subject level with normal distribution around the parameters
parameters {
  // phs
  vector[4] mus_phs;
  vector<lower=0>[4] sigmas_phs;
  matrix[4,S] difs_phs;

  // age
  vector[2] mus_age; //age coefficients for phs, rt, ndt and conf
}

//transformed parameters for the model
// check that this is correct with Jesper
transformed parameters {

  // intercepts and slopes for each subject
  // phs
  vector[S] a_phs = exp(to_vector(mus_phs[1]+(difs_phs[1,])*sigmas_phs[1])+mus_age[1].*age_z);
  vector[S] b_phs = exp(to_vector(mus_phs[2]+(difs_phs[2,])*sigmas_phs[2])+mus_age[2].*age_z);
  vector[S] g_phs = to_vector(inv_logit(mus_phs[3]+(difs_phs[3,])*sigmas_phs[3])/2);
  vector[S] l_phs = to_vector(inv_logit(mus_phs[4]+(difs_phs[4,])*sigmas_phs[4])/2);

}

// The model to be estimated. 
model {
  vector[N] p;

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
  
  // age priors
  mus_age ~ normal(0,0.3);
  
  //cut points for each participant
  for(s in 1:S){
  
    p[starts[s]:ends[s]] = g_phs[s]+(1-g_phs[s]-l_phs[s])*(inv_logit(b_phs[s]*(tcf[starts[s]:ends[s]]-a_phs[s]))); //log_probit function
    phs[starts[s]:ends[s]] ~ bernoulli(p[starts[s]:ends[s]]);
  
  }
  
  
}

generated quantities{
  // log likelihoods
  vector[N] ll_bin;
  vector[N] log_lik;
  vector[N] p_gq;
  
  for(n in 1:N){
    p_gq[n] = g_phs[S_id[n]]+(1-g_phs[S_id[n]]-l_phs[S_id[n]])*(inv_logit(b_phs[S_id[n]]*(tcf[n]-a_phs[S_id[n]]))); //log_probit function
    ll_bin[n] = bernoulli_lpmf(phs[n]|p_gq[n]);
    log_lik[n] = ll_bin[n];
  }
}
