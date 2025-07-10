# Thermal contrast enhancement and paradoxical heat sensation across the lifespan - Preregistration

Here you'll find example scripts for running the two multivariate models on simulated data. This can be found in the markdown where both model 1 and model 2 
are shown. These also plots the results of these models on the simulated data.

## **Repository Structure**  

The repository is structured in the following way:

phs-simulation_m1.Rmd

```         
phs-ageing/preregistration
│
├── plots/                 # Plots from the preregistration
│   └── ... 
├── phs-simulation_m1.Rmd  # Markdown for running model 1 on simulated data
│  
├── phs-simulation_m2.Rmd  # Markdown for running model 2 on simulated data
│   
├── Recover_Power/         # Folder containing everything regarding model and parameter recovery and individual difference analysis.
│   ├── Run_simulation.Rmd            # Rmarkdown for running the parameter recovery & model recovery and power investigation.
│   ├── power_parameter_scripts.R     # R-scripts for running the whole thing in parallel
│   ├── visualisations.Rmd            # Rmarkdown for visualizing the results of the preregistration analysis.
│   ├── Methods.Rmd                   # Rmarkdown for the Methods
│   ├── Supplementary material.Rmd    # Rmarkdown for the Supplementary material.
│   ├── individual-differences/       # R-objects generated for reporting the main manuscript.
│   ├── plots/                        # Figure for the main manuscript.
│   └── results/                      # results obtained from the "Run_simulations.Rmd"
│
├── stanmodels/            # Stanmodels
│   └── ... 
└── README.md             # overview of the project.


```
