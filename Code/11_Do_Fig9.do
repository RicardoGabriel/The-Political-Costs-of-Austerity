				*** 11_Do_Fig9.do ***


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


********************************************************************************
*Step 1)					DATA PREPARATION
********************************************************************************


*List of dependent variables
local lhsrealvarlist pcGDP // Emp pcInv pcVehicles Comp LaborShare  


*forward change of LHS real variables in growth rates (%)
foreach lhsvar in `lhsrealvarlist'{	
	forvalues i = 0/`horizon'{
		if "`lhsvar'" == "pcGOV"{
			gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV *100
			label var F`i'`lhsvar' "Forward `i' year change in `lhsvar' relative to pcGDP, percent %"
		}
		else if  ("`lhsvar'" == "pubEmpAbs" | "`lhsvar'" == "privEmpAbs") {
			gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.EmpAbs *100
			label var F`i'`lhsvar' "Forward `i' year change in `lhsvar', percent %"
		}
		else if  "`lhsvar'" == "LaborShare"  {    				
			gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar' )*100
			label var F`i'`lhsvar' "Forward `i' year change in `lhsvar', percent %"
		}
		else {
			gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.`lhsvar' *100
			label var F`i'`lhsvar' "Forward `i' year change in `lhsvar', percent %"

		}
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
*** 2.1) Impulse Response Function - Cumulative Dep. Variable
********************************************************************************

* controls in LP regression
foreach lhsvar in `lhsrealvarlist'{
	if "`lhsvar'" == "pcGOV"{
		local rhscontrols`lhsvar' l(1/`MaxLPLags').F0`lhsvar'RHS 
	}
	else{
		local rhscontrols`lhsvar' l(1/`MaxLPLags').F0pcGOVRHS l(1/`MaxLPLags').F0`lhsvar'
	}
}

foreach lhsvar in `lhsrealvarlist' {

	*variables to store the impulse response (vector of betas from the LP regressions) and standard errors
	cap gen b_`lhsvar'_iv  = .
	cap gen se_`lhsvar'_iv = .
	cap gen Fstat_`lhsvar'_iv = .
	
	local var pcGOV
	
	*** Baseline LP table Using IV
	* One regression for each horizon of the response (0-4 years)
	forvalues i = 0/`horizon' {
		local ord = `i' + 1 			// ord='i'+1 in ivreg2 is equivalent to ord='i' in xtscc (check "help ivreg2")
		if (("`lhsvar'" == "pcGOV") & `i' ==0){
			local ord = 0
		}
		
		* LP regression	
		xi: ivreg2 F`i'`lhsvar' (F0`var'RHS  = `inst') `rhscontrols`lhsvar'' ///
		i.id i.Year, cluster(id) partial(`rhscontrols`lhsvar'' i.id i.Year)

		replace b_`lhsvar'_iv  		= _b[F0`var'RHS] if _n == `i'+1
		replace se_`lhsvar'_iv 		= _se[F0`var'RHS] if _n == `i'+1			
	}
	
***********************Baseline IV LP graphs**********************************
		
	* time variable	
	cap gen periods = _n - 1 if _n <= `horizon' +1

	* zero line
	cap gen zero = 0 if _n <= `horizon' +1
	***** create confidence bands (in this case 90 and 90%) ****
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
	if "`lhsvar'" == "LaborShare" { 
		twoway (rarea up_`lhsvar' dn_`lhsvar' periods, ///
		fcolor(gs12) lcolor(white) lpattern(solid)) ///
		(rarea up2_`lhsvar' dn2_`lhsvar' periods, ///
		fcolor(gs10) lcolor(white) lpattern(solid)) ///
		(line b_`lhsvar'_iv periods, lcolor(blue) ///
		lpattern(solid) lwidth(thick)) /// 
		(line zero periods, lcolor(black)), scale(1.4) ///
		ytitle("p.p.") xtitle("Year") ///
		graphregion(color(white)) plotregion(color(white)) legend(off)		
	}
	else{
		twoway (rarea up_`lhsvar' dn_`lhsvar' periods, ///
		fcolor(gs12) lcolor(white) lpattern(solid)) ///
		(rarea up2_`lhsvar' dn2_`lhsvar' periods, ///
		fcolor(gs10) lcolor(white) lpattern(solid)) ///
		(line b_`lhsvar'_iv periods, lcolor(blue) ///
		lpattern(solid) lwidth(thick)) /// 
		(line zero periods, lcolor(black)), scale(1.4) ///
		ytitle("percent") xtitle("Year") ///
		graphregion(color(white)) plotregion(color(white)) legend(off)		
	}

	*save figures
	if "`lhsvar'" == "pcGDP" {
		graph export "$Fig\Fig9a`Italy'.pdf", replace
	}
	else if "`lhsvar'" == "Emp" {
		graph export "$Fig\Fig9b`Italy'.pdf", replace
	}
	else if "`lhsvar'" == "pcInv" {
		graph export "$Fig\Fig9c`Italy'.pdf", replace
	}
	else if "`lhsvar'" == "pcVehicles" {
		graph export "$Fig\Fig9d`Italy'.pdf", replace
	}
	else if "`lhsvar'" == "Comp" {
		graph export "$Fig\Fig9e`Italy'.pdf", replace
	}
	else if "`lhsvar'" == "LaborShare" {
		graph export "$Fig\Fig9f`Italy'.pdf", replace
	}
	
}

