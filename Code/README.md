# The Political Costs of Austerity - Code

Inside this folder [Code](https://github.com/RicardoGabriel/The-Political-Costs-of-Austerity/tree/main/Code) you can find all Stata codes used to produce the figures and tables in the paper.

Recommended version: Stata 15

To run the codes, one need to set the appropriate path in the Paths.do file and run the Master.do. The Master.do has a small control panel where one can change settings such as: the main instrument being used or the level of Nuts for the analysis (currently only Nuts 2 will work given the availability of election data). The Master.do calls all necessary do files to produce each figure or table, conveniently named after the name in the paper - example being you run Fig1.do file to produce Figure 1 in the paper.

In this folder, you can also find the key do file, "Preamble", we use in our data management to create the different Bartik Instruments we use in our analysis. They are named: Alesina4 (baseline) IMF Alesina5 and Alesina4_unpredicted Alesina4_fracmil2_lag (used robustness checks in Table C3). And also to compile the baseline datasets.

Finally, there are two files in this folder used to produce the European maps figures - the coordinates file "eucoord.dta" and a shape file "eucoord_shp.dta".