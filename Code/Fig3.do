* Government spending response to austerity


* number of lags
local MaxLPLags 2
* horizon
local horizon 4

*instrument 
local inst = "$inst"

use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

*to have the same sample when looking at real and political variables
drop if Far_share==.


********************************************************************************
*Step 1)					DATA PREPARATION
********************************************************************************

*List of dependent variables
local lhsrealvarlist pcGOV 

*forward change of LHS real variables in growth rates (%)
foreach lhsvar in `lhsrealvarlist'{	
	forvalues i = 0/`horizon'{
		gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV *100
		label var F`i'`lhsvar' "Forward `i' year change in `lhsvar' relative to pcGDP, percent %"
	
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
		label var F`i'`lhsvar' "Forward `i' year change in `lhsvar' * (-1), percent %"
	}
}

********************************************************************************
*Step 2)					LOCAL PROJECTIONS
********************************************************************************

*******************************************************************************
*** 2.1) Impulse Response Function - Cumulative Dep. Variable
********************************************************************************

* controls in LP regression
local rhscontrols`lhsvar' l(1/`MaxLPLags').F0`lhsvar'RHS l(1/`MaxLPLags').F0pcGDP


foreach lhsvar in `lhsrealvarlist' {
	local var pcGOV
	
	*variables to store the impulse response (vector of betas from the LP regressions) and standard errors
	cap gen b_`lhsvar'_iv  = .
	cap gen se_`lhsvar'_iv = .
	cap gen Fstat_`lhsvar'_iv = .
	
		
		*** Baseline LP table Using IV
		* One regression for each horizon of the response (0-4 years)
		forvalues i = 0/`horizon' {

		if (`i' ==0){
			* LP regression	
			xi: ivreg2 F`i'`lhsvar' (F0`var'RHS  = `inst') `rhscontrols`lhsvar'' ///
			i.id i.Year, partial(`rhscontrols`lhsvar'' i.id i.Year)
		}
	
		if (`i' >0){
			* LP regression	
			xi: ivreg2 F`i'`lhsvar' (F0`var'RHS  = `inst') `rhscontrols`lhsvar'' ///
			i.id i.Year, cluster(id) partial(`rhscontrols`lhsvar'' i.id i.Year)
		}
		
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
		twoway (rarea up_`lhsvar' dn_`lhsvar' periods, ///
		fcolor(gs12) lcolor(white) lpattern(solid)) ///
		(rarea up2_`lhsvar' dn2_`lhsvar' periods, ///
		fcolor(gs10) lcolor(white) lpattern(solid)) ///
		(line b_`lhsvar'_iv periods, lcolor(blue) ///
		lpattern(solid) lwidth(thick)) /// 
		(line zero periods, lcolor(black)), scale(1.4) ///
		ytitle("percent") xtitle("Year") ///
		graphregion(color(white)) plotregion(color(white)) legend(off)		
		
		graph export "$Fig\Fig3.eps", replace
		graph export "$Fig\Fig3.pdf", replace
	
}

