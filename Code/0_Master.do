					*** Master.do ***
 
*Authors: Ricardo Duque Gabriel, Mathias Klein, and Ana Sofia Pessoa
*Start Date: 04/12/2020
*Last Update: 10/05/2023

clear all
set more off
set matsize 11000

graph set window fontface  "Linux Libertine O"     // set default font (window)
graph set window fontfacesans  "Linux Libertine O"  // set default sans font (window)
graph set window fontfaceserif "Linux Libertine O"    // set default serif font (window)
graph set window fontfacemono "Linux Libertine O"    // set default mono font (window)
set varabbrev off

*Choose Nuts level to perform the analysis on
global nu = 2

*Choose main instrument (IMF or Alesina1-4)
local inst Alesina4
local instrument "Alesina4"
global inst Alesina4
	
* Do you want to clean the data? 0= no; 1= yes.
local clean = 0

* uncomment first to produce all results excluding Italy
*global noItaly _noItaly
global noItaly
	
********************************************************************************
* DATA PREPARATION: Running Cleaning and Analysis
********************************************************************************
do Paths

if `clean' == 1 {
	* Cleaning Election Data 
	do DataPrep\Master_CleaningElection

	* Cleaning IMF Shocks
	do ${hp}Code\DataPrep\Cleaning_IMFShocks

	forvalue x = 1/4 {
		* Always prepare data on real economy
		do ${hp}Code\DataPrep\Preamble_RealVar
		
			* Merge Dataset of real variables with IMF shocks and election data
			if `x' == 1 {
				do ${hp}Code\DataPrep\Merge_Datasets_NationalElections
			}
			else if `x' == 2 {
				do ${hp}Code\DataPrep\Merge_Datasets_RegionalElections
			}
			else if `x' == 3 {
				do ${hp}Code\DataPrep\Merge_Datasets_EuropeanElections
			}
			else if `x' == 4{
				do ${hp}Code\DataPrep\Merge_Datasets
			}
	}

}
*order check* Valid Votes F0* Far_Left Far_Right Year Nuts_id
*keep if cid==5

********************************************************************************
* ANALYSIS - Main Text
********************************************************************************
cd "${hp}Code\Analysis"



*Figure 1
do 1_Do_Fig1

*Figure 2
do 2_Do_Fig2

*Figure 3
do 4_Do_Fig4

*Figure 4 	
do 5_Do_Fig5	

*Figure 5 	
do 6_Do_Fig6

*Table 1
do 7_Do_Tab1
 
*Table 2
do 8_Do_Tab2

*Figure 6
do 9_Do_Fig7

*Figure 7
do 10_Do_Fig8
	
*Figure 8
do 11_Do_Fig9	
	
*Table 3 and Table C.4
do 12_Do_Tab3
	
*Figure 10	
do 13_Do_Fig10

*Figure Decomposition Revision
do 18_Revision_Decomposition

*Some new revision Tables and Figures
do 17_Revision


********************************************************************************
* ANALYSIS - Appendix
********************************************************************************
*Figure C1
do 14_Do_FigC1
 
*Table C2
do 15_Do_TabC1

*Fgure D2
do 16_Do_FigD2


*Correlation Tables
*run new cleaning exercise:
global nu = 0
do ${hp}Code\DataPrep\Preamble_RealVar
keep if Nuts == $nu 
merge m:m Country Year using "$hp\Outputs\Data_aux\OECD_NA.dta"
drop if _merge==2
drop _merge
keep if Country == "Austria" |	Country == "Finland" | Country == "France" | Country == "Germany" | Country == "Italy" | Country == "Portugal" |  Country == "Spain" | Country == "Sweden" 
save "${hp}\Outputs\Data_aux\Data_Analysis_Nuts0.dta", replace
cd "${hp}Code\Analysis"

do A1_Table_Corr
do A2_Table_Corr
do A3_Table_Corr
