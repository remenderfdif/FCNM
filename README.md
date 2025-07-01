# FCNM

This code is based on the MATLAB platform. 

First, you need to add dpabi, spm, and ROI_ball_gen.m to the Path. 

FCNM.m is used to run functional connectivity network mapping. The main steps included: (1) Read the basic information and header for each individual study; (2) Create an Excel table with the coordinates of all the articles, and then manually fill in the corresponding table with the coordinates of all the articles; (3) Generate spheres based on the ROI of each study and merge spheres from the same study; (4) Calculate functional connectivity with dpabi; (5) one-sample t-test and model estimation.

combat.m -- If there are multiple sites, you can use combat.m to remove inter-site effects.
