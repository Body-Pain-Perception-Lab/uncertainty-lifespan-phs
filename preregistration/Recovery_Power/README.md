
# Simulation analysis overview

There are two main markdowns that take the information from the simulation study and displays there results.

The first markdown is Visualizations.Rmd. 
This markdown displays the main parameter and model recovery as well as the power consideration (as this is essentially the same). 
This markdown uses the results directory where the results from the simulation analysis is stored.


The second markdown is inside the individual differences directory called plot_indi_dif.Rmd. 
This markdown firstly simulates 83 subjects for each model and then goes on to fit these subjects on a single subject basis. 
Here the simulations that i used for the plots in the pre-reg is stored in the workspace.Rdata file inside of the individual differnces directory. 


The last markdown (Run_simulation.Rmd) is to run the simulation analysis, which draws on the functions and R-scripts inside of power_parameter_scripts.R.