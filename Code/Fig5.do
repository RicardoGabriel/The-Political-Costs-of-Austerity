*Responses of voter turnout, total votes for extreme parties, and fragmentation


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
local lhsvarlist Turnout Far Fragmentation

* forward change of LHS variable electoral dependent variables
egen Far 	= rowtotal(Far_Right Far_Left)	
replace Far = Far/EligibleVoters

*fragmentation
gen Fragmentation = 1-HHI

* create lags of electon type for controls
foreach var in ElectionType{
	replace `var' = `var'[_n-1] if `var' == . & Nuts_id == Nuts_id[_n-1]
}
	
foreach var in `lhsvarlist' {
	*gen log`var' = log(1+(100*`var'))
	forvalues i=0/`horizon' {
		*qui gen F`i'`var' = 100*(F`i'.log`var' - L.log`var')
		*label var F`i'`var' "Forward `i' year change in `var', percent %"
		qui gen F`i'`var' = 100*(F`i'.`var' - L.`var')
		label var F`i'`var' "Forward `i' year change in `var', pp"
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
	local rhscontrols`lhsvar' l(1/`MaxLPLags').F0`lhsvar' l(1/`MaxLPLags').F0pcGOVRHS l(1/`MaxLPLags').F0pcGDP
}

foreach lhsvar in `lhsvarlist'  {

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
			cluster(id) partial(`rhscontrols`lhsvar'' i.id i.Year)
			
			cap gen xsample=e(sample)
					
			*estat firststage
			replace b_`lhsvar'_iv  		= _b[F0`var'RHS] if _n == `i'+1
			replace se_`lhsvar'_iv 		= _se[F0`var'RHS] if _n == `i'+1

				
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
		
		}
		
		* graphs	
		** LPs Turnout Far Fragmentation
		twoway (rarea up_`lhsvar' dn_`lhsvar' periods, ///
		fcolor(gs12) lcolor(white) lpattern(solid)) ///
		(rarea up2_`lhsvar' dn2_`lhsvar' periods, ///
		fcolor(gs10) lcolor(white) lpattern(solid)) ///
		(line b_`lhsvar'_iv periods, lcolor(blue) ///
		lpattern(solid) lwidth(thick)) /// 
		(line zero periods, lcolor(black)), scale(1.4) ///
		ytitle("p.p.") xtitle("Year") ///
		graphregion(color(white)) plotregion(color(white)) legend(off)
		
		if "`lhsvar'" == "Turnout" {
			graph export "$Fig\Fig5a.eps", replace
			graph export "$Fig\Fig5a.pdf", replace
		}
		else if "`lhsvar'" == "Far" {
			graph export "$Fig\Fig5b.eps", replace
			graph export "$Fig\Fig5b.pdf", replace
		}
		else if "`lhsvar'" == "Fragmentation" {
			graph export "$Fig\Fig5c.eps", replace
			graph export "$Fig\Fig5c.pdf", replace
		}		
	
	
	
	}
}
