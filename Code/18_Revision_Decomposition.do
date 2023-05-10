
* number of lags
local MaxLPLags 2
* horizon
local horizon 4
*instrument 
local inst = "$inst"

use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

local Italy = "$noItaly"
if "`Italy'" == "_noItaly"{
	drop if cid == 5
}

*drop if cid == 5


*to have the same sample when looking at real and political variables
drop if Far_share==.
 
********************************************************************************
*Step 1)					DATA PREPARATION
********************************************************************************

*List of dependent variables
local lhsvarlist Far_share Incumbent_share Moderates_share


*forward changes for main variables
foreach var in Far_share {

	replace L1Incumbent = L1Incumbent / L1.Votes
	replace L1Far_Incumbent = L1Far_Incumbent / L1.Votes
	replace L1Moderates = L1Moderates / L1.Votes

	forvalues i=0/`horizon' {
		qui gen F`i'`var' = 100*(F`i'.`var' - L.`var')
		label var F`i'`var' "Forward `i' year change in `var', pp"
		
		replace F`i'Incumbent = F`i'Incumbent/F`i'.Votes
		replace F`i'Far_Incumbent = F`i'Far_Incumbent/F`i'.Votes
		
		qui gen F`i'Incumbent_share = 100*(F`i'Incumbent - L1Incumbent - (F`i'Far_Incumbent - L1Far_Incumbent))
		label var F`i'Incumbent_share "Forward `i' year change in Incumbent share, pp"
		
		replace F`i'Moderates = F`i'Moderates/F`i'.Votes
		
		qui gen F`i'Moderates_share = 100*(F`i'Moderates - L1Moderates)
		label var F`i'Moderates_share "Forward `i' year change in Moderates share, pp"		
	}
} 

*forward changes for control variables
foreach lhsvar in pcGDP {	
	forvalues i = 0/`horizon'{	
		gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.`lhsvar' *100
		label var F`i'`lhsvar' "Forward `i' year change in `lhsvar', percent %"		
	}
}

*forward change of RHS variable in growth rates (%)
foreach lhsvar in pcGOV {
	forvalues i = 0/`horizon' {
		gen F`i'`lhsvar'RHS = (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100)    // *(-1) because we want to analyze the impact of austerity: a drop in gov spending!
	}
}


********************************************************************************
*Step 2)					LOCAL PROJECTIONS
********************************************************************************

*******************************************************************************
*** 2.1) Impulse Response Function - Cumulative
********************************************************************************

* controls in LP regression
foreach lhsvar in `lhsvarlist' {
	local rhscontrols`lhsvar'  l(1/`MaxLPLags').F0pcGOVRHS l(1/`MaxLPLags').F0pcGDP
	
	* exclude lags of osame variable to allow for comparability across different vote shares 
	* (adding does not change the results, but does not allow to add all changes to zero as it should)
	*l(1/`MaxLPLags').F0`lhsvar'
}

foreach lhsvar in `lhsvarlist'   {/*LHS variable: `lhsvarlist' */

	*variables to store the impulse response (vector of betas from the LP regressions) and standard errors
	cap gen b_`lhsvar'_iv  = .
	cap gen se_`lhsvar'_iv = .
	cap gen Fstat_`lhsvar'_iv = .
	
	foreach var in pcGOV {
		
		*** Baseline LP table Using IV
		* One regression for each horizon of the response (0-4 years)
		forvalues i = 0/`horizon' {		
			
			* LP regression	
			xi: ivreg2 F`i'`lhsvar' (F0`var'RHS  = `inst') ///
			`rhscontrols`lhsvar'' i.id i.Year,  ///
			cluster(id) partial(`rhscontrols`lhsvar'' i.id  i.Year)

			cap gen xsample=e(sample)
			
			
			*estat firststage
			replace b_`lhsvar'_iv  		= _b[F0`var'RHS] if _n == `i'+1
			replace se_`lhsvar'_iv 		= _se[F0`var'RHS] if _n == `i'+1
					
		}

	
	***********************Baseline IV LP graphs**********************************
			
		* time variable	
		cap gen periods = _n - 1 if _n <= `horizon' +1

		* zero line
		cap gen zero = 0 if _n <= `horizon' +1
		
		***** create confidence bands (in this case 95 and 90%) ****
		scalar sig1 = 0.05	 // specify significance level
		scalar sig2 = 0.10	 // specify significance level
		
		cap gen up_`lhsvar'  = .
		cap gen dn_`lhsvar'  = .
		cap gen up2_`lhsvar' = .
		cap gen dn2_`lhsvar' = .

		*confidence intervals
		replace up_`lhsvar' 	= b_`lhsvar'_iv  + invnormal(1-sig1/2)*se_`lhsvar'_iv  if _n <= (`horizon' + 1)
		replace dn_`lhsvar' 	= b_`lhsvar'_iv  - invnormal(1-sig1/2)*se_`lhsvar'_iv  if _n <= (`horizon' + 1)
		replace up2_`lhsvar' 	= b_`lhsvar'_iv  + invnormal(1-sig2/2)*se_`lhsvar'_iv  if _n <= (`horizon' + 1)
		replace dn2_`lhsvar' 	= b_`lhsvar'_iv  - invnormal(1-sig2/2)*se_`lhsvar'_iv  if _n <= (`horizon' + 1)

		* graphs
		** LPs
		twoway (rarea up_`lhsvar' dn_`lhsvar' periods, ///
		fcolor(gs12) lcolor(white) lpattern(solid)) ///
		(rarea up2_`lhsvar' dn2_`lhsvar' periods, ///
		fcolor(gs10) lcolor(white) lpattern(solid)) ///
		(line b_`lhsvar'_iv periods, lcolor(blue) ///
		lpattern(solid) lwidth(thick)) /// 
		(line zero periods, lcolor(black)), scale(1.4) ///
		ytitle("p.p.") xtitle("Year") ///
		graphregion(color(white)) plotregion(color(white)) legend(off)

		graph export "$Fig\Fig_Decomposition_`lhsvar'`Italy'.pdf", replace
		
	}
}

