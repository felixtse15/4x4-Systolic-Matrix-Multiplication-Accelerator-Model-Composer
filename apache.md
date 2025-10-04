apply gradient descent to find optimization. each driver stage is a variable to optimize,
so 3 stages is 3 variable optimization, 5 stages is 5 variable optimization.

-gradient descent: slightly change each individual value by a small step size, check the effect on delay.
- these individually changed delays are compared to the base delay, which creates a gradient. that gradient is 
applied to the old size to create new sizes, create a new base delay. and so forth until delay is minimized, 
which is when gradient is less than step size, or reach 20 iterations

i have a few functions:

sim_parse: this is the base delay extraction. it runs hspice simulation, and extracts all the delays, and stores it in
some buffer files called outputn.txt

get-metrics gets the base delay and base energy for your main params

new-s-values performs gradient descent using past sizes, current delay, past delay, step size, num stages for the loop, and learning rate

set-s is the initialization of the netlist, when you want to run optimization for a new set of stages,
it populates the parameters with S1, S2, S3 etc., instantiates drivers, and add initial .alter blocks to set up
gradient descent

change_dsize rewrites the alter values in the netlist to check for gradient descent.

change_base_s_values changes the main param values after a new base size has been found from the gradient

0.2mm