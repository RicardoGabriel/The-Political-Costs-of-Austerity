* Multipliers estimation
 
* number of lags
local MaxLPLags 2
* horizon
local horizon 4
*instrument 
local inst = "$inst"


use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

********************************************************************************
*Step 1)					DATA PREPARATION
********************************************************************************

*List of real dependent variables
local lhsrealvarlist pcGDP Emp 

*forward change of LHS real variables in growth rates (%)
gen cum_inst = 0

foreach lhsvar in `lhsrealvarlist' `inst'{
	forvalues i = 0/`horizon' {
		if  ("`lhsvar'" == "pubEmp" | "`lhsvar'" == "privEmp") {
			gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.Emp *100
		}
		else{		
			gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.`lhsvar' *100
			label var F`i'`lhsvar' "Forward `i' year change in `lhsvar', percent %"
		}
	}
}

*forward change of RHS variable in growth rates (%)
foreach lhsvar in pcGOV {
	forvalues i = 0/`horizon' {
		gen F`i'`lhsvar'RHS = (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *(-100)   // *(-1) because we want to analyze the impact of austerity a drop in gov spending!
		label var F`i'`lhsvar'RHS "Forward `i' year change in `lhsvar' * (-1), percent %"
	}
}

* Cumulative variables for multiplier computation
foreach var in `lhsrealvarlist' pcGOVRHS `inst' { 
	qui gen cum_`var'=0
	forvalues i=0/`horizon' {
		gen cum`i'_`var'=F`i'`var' + cum_`var'
		replace cum_`var'=cum`i'_`var'
	}
	drop cum_`var'
}

********************************************************************************
*Step 2)					LOCAL PROJECTIONS
********************************************************************************

*******************************************************************************
*** 2.1) Impulse Response Function - Cumulative
********************************************************************************
cap gen shock=.
lab var shock "Multiplier"

* controls in LP regression
foreach lhsvar in `lhsrealvarlist' {
	local rhscontrols`lhsvar' l(1/`MaxLPLags').F0pcGOVRHS l(1/`MaxLPLags').cum0_`lhsvar' 
}

foreach lhsvar in `lhsrealvarlist' {

	*variables to store the impulse response (vector of betas from the LP regressions) and standard errors
	cap gen b_`lhsvar'_iv  = .
	cap gen se_`lhsvar'_iv = .
	cap gen Fstat_`lhsvar'_iv = .
	
	foreach var in pcGOV {
		
		*** Baseline LP table Using IV
		* One regression for each horizon of the response (0-4 years)
		forvalues i = 0/`horizon' {

			replace shock = cum`i'_`var'RHS

			* LP regression
			xi: ivreg2 cum`i'_`lhsvar' (shock  = `inst') ///
			`rhscontrols`lhsvar'' i.id i.Year,  ///
			cluster(id) partial(`rhscontrols`lhsvar'' i.id i.Year)
					
			
			*estat firststage
			eststo iv_`lhsvar'F`i'
			replace b_`lhsvar'_iv  		= _b[shock] if _n == `i'+1
			replace se_`lhsvar'_iv 		= _se[shock] if _n == `i'+1
			replace Fstat_`lhsvar'_iv 	= e(widstat) if _n == `i'+1
			if (e(widstat)>= 23.1){
				replace Fstat_`lhsvar'_iv =  23.1 if _n == `i'+1
			}						
		}
		
	
	***********************Baseline MULT graphs**********************************
			
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
		ytitle("") xtitle("Horizon") ///
		graphregion(color(white)) plotregion(color(white)) legend(off)
		
		if "`lhsvar'" == "pcGDP" {
			graph export "$Fig\FigD1a.eps", replace
		}
		else if "`lhsvar'" == "Emp" {
			graph export "$Fig\FigD1b.eps", replace
		}
	}
}
