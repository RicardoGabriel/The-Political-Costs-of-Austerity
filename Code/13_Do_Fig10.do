				*** 13_Do_Fig10.do ***


use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear
merge 1:1 Nuts_id Year using "${hp}\Data\Trust_Algan.dta"
drop if _merge == 2
sort id Year
rename trstprl_new Trust


* Define which variable to use to identify recessions (pcGDP or Employment_Total)
local recession_id pcGVA

gen pcGVA = GVA_Total / Population


local Italy = "$noItaly"
if "`Italy'" == "_noItaly"{
	drop if cid == 5
}


*to have the same sample when looking at real and political variables
drop if Far_share==.

* number of lags
local MaxLPLags 2
* horizon
local horizon 4

*Choose main instrument (IMF or Alesina1-4)
local inst Alesina4
local instrument "Alesina4"
global inst Alesina4

*List of dependent variables
local lhsvarlist Far_share
local lhstrust Trust
local lhsrealvarlist pcGDP Employment_Total pcGVA

foreach var in Trust{
	replace `var' = `var'[_n-1] if `var' == . & Nuts_id == Nuts_id[_n-1]
}

** For SD specfication
* forward change of LHS variable electoral dependent variables
foreach var in `lhsvarlist' {
	forvalues i=0/`horizon' {
		qui gen F`i'`var' = 100*(F`i'.`var' - L.`var')
		label var F`i'`var' "Forward `i' year change in `var', pp"
	}
}	

foreach var in `lhstrust' {
	forvalues i=0/`horizon' {
		qui gen F`i'`var' = 100*(F`i'.`var')
		label var F`i'`var' "`var', pp"
	}
}	

*forward changes for control variables
foreach lhsvar in `lhsrealvarlist'{	
	forvalues i = 0/`horizon'{	
		cap gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.`lhsvar' *100
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
*Step 1)					DATA PREPARATION
********************************************************************************
*********************************************
***** 	 GENERATE STATE VARIABLES   	*****
*********************************************
local state = "recession"
local low "AusterityRecession"
local high "Recession"


* Dummy for recessions with austerity
gen recession_w_a 		= 0 if ( F0`recession_id' < 0 & Alesina4 <= 0 & Alesina4 !=. & F0`recession_id' !=. ) | ( F0`recession_id' > 0 & F0`recession_id'!=. )
replace recession_w_a 	= 1 if F0`recession_id' < 0 & Alesina4 > 0 & Alesina4 !=. & F0`recession_id'!=.

*Dummy expansion
gen expansion 			= 0 if ( F0`recession_id' < 0 & Alesina4 <= 0 & Alesina4 !=. & F0`recession_id' !=. ) | (F0`recession_id' < 0 & Alesina4 > 0 & Alesina4 !=. & F0`recession_id'!=.)
replace expansion 		= 1 if F0`recession_id' > 0 & F0`recession_id'!=.

* Dummy for recessions without austerity
gen recession_wo_a 		= 0 if ( F0`recession_id' > 0 & F0`recession_id'!=. ) | (F0`recession_id' < 0 & Alesina4 > 0 & Alesina4 !=. & F0`recession_id'!=.)
replace recession_wo_a 	= 1 if F0`recession_id' < 0 & Alesina4 <= 0 & Alesina4 !=. & F0`recession_id' !=. 
 
*********************************************
***** 	 GENERATE LHS VARIABLES 	*****
*********************************************
* forward change of LHS variable electoral dependent variables
foreach var in `lhsvarlist' {
	forvalues i=0/`horizon' {
		qui gen F`i'`var'_r_w_a 	= 100*(F`i'.`var' - L.`var') * recession_w_a
		qui gen F`i'`var'_r_wo_a 	= 100*(F`i'.`var' - L.`var') * recession_wo_a
		qui gen F`i'`var'_e 		= 100*(F`i'.`var' - L.`var') * (1 - recession_w_a - recession_wo_a)
	}
}		

foreach var in `lhstrust' {
	forvalues i=0/`horizon' {
		qui gen F`i'`var'_r_w_a 	= 100*(F`i'.`var') * recession_w_a
		qui gen F`i'`var'_r_wo_a 	= 100*(F`i'.`var') * recession_wo_a
		qui gen F`i'`var'_e 		= 100*(F`i'.`var') * (1 - recession_w_a - recession_wo_a)
	}
}

*forward change of LHS real variables in growth rates (%)
foreach lhsvar in `lhsrealvarlist'{	
	forvalues i = 0/`horizon'{
		gen F`i'`lhsvar'_r_w_a	 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100 * recession_w_a
		gen F`i'`lhsvar'_r_wo_a 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100 * recession_wo_a
		gen F`i'`lhsvar'_e 			= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100 * (1 - recession_w_a - recession_wo_a)
	}
}

*forward change of LHS variable scaled by lagged pcGDP
** State dependent variables
cap gen Alesina4_r_w_a 	= Alesina4 * recession_w_a
cap gen Alesina4_e		= Alesina4 * (1 - recession_w_a - recession_wo_a)

foreach lhsvar in pcGOV {
	forvalues i = 0/`horizon' {
		cap gen F`i'`lhsvar' 		= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100)
		cap gen F`i'`lhsvar'_r_w_a 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100) * recession_w_a
		cap gen F`i'`lhsvar'_r_wo_a = (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100) * recession_wo_a
		cap gen F`i'`lhsvar'_e		= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100) * (1 - recession_w_a - recession_wo_a)

	}
}

*******************************************************************************
*** Multipliers
********************************************************************************
cap gen shock_r_w_a			= .
cap gen shock_r_wo_a		= .
cap gen shock_e			    = .
cap gen shock				= . 
foreach lhsvar in `lhsvarlist' `lhstrust' {/*LHS variable*/
	
	*variables to store the impulse response (vector of betas from the LP regressions) and standard errors
	 gen b_`lhsvar'_r_w_a  			= .
	 gen se_`lhsvar'_r_w_a  		= .
	 gen Fstat_`lhsvar'_r_w_a  		= .
	
	 gen b_`lhsvar'_r_wo_a  		= .
	 gen se_`lhsvar'_r_wo_a  		= .
	 gen Fstat_`lhsvar'_r_wo_a  	= .
	
	 gen b_`lhsvar'_r_w_a_d  		= .
	 gen se_`lhsvar'_r_w_a_d  		= .
	 gen Fstat_`lhsvar'_r_w_a_d  	= .
	
	 gen b_`lhsvar'_r_wo_a_d 		= .
	 gen se_`lhsvar'_r_wo_a_d  		= .
	 gen Fstat_`lhsvar'_r_wo_a_d  	= .	
	
	 gen b_`lhsvar'_e 				= .
	 gen se_`lhsvar'_e 				= .
	 gen Fstat_`lhsvar'_e 			= .
	 
	 gen b_`lhsvar'_e_d 			= .
	 gen se_`lhsvar'_e_d 			= .
	 gen Fstat_`lhsvar'_e_d 		= .
	 
	 gen ptest_`lhsvar'_c 			= . 
	 gen ptest_`lhsvar' 			= . 
	 gen hacph_`lhsvar' 			= .
	 gen arph_`lhsvar'  			= .
	 gen arph_`lhsvar'_c  			= .

	 foreach var in pcGOV{	
		
		* controls in LP regression

		if ("`lhsvar'" == "Far_share") {
			local rhscontrols_r_w_a l(1/`MaxLPLags').F0Far_share_r_w_a l(1/`MaxLPLags').F0pcGOV_r_w_a l(1/`MaxLPLags').F0`recession_id'_r_w_a recession_w_a 
			local rhscontrols_r_wo_a l(1/`MaxLPLags').F0Far_share_r_wo_a l(1/`MaxLPLags').F0pcGOV_r_wo_a l(1/`MaxLPLags').F0`recession_id'_r_wo_a  
			local rhscontrols_e l(1/`MaxLPLags').F0Far_share_e l(1/`MaxLPLags').F0pcGOV_e l(1/`MaxLPLags').F0`recession_id'_e expansion
		}
		else {
			local rhscontrols_r_w_a l(1/`MaxLPLags').F0pcGOV_r_w_a l(1/`MaxLPLags').F0`recession_id'_r_w_a recession_w_a 
			local rhscontrols_r_wo_a l(1/`MaxLPLags').F0pcGOV_r_wo_a l(1/`MaxLPLags').F0`recession_id'_r_wo_a  
			local rhscontrols_e l(1/`MaxLPLags').F0pcGOV_e l(1/`MaxLPLags').F0`recession_id'_e expansion
		}
		*** Baseline LP table Using IV
		* One regression for each horizon of the response (0-4 years)
		forvalues i = 0/`horizon' {
			local ord = `i' + 1

			replace shock_r_w_a 	= F0pcGOV_r_w_a 
			replace shock_r_wo_a 	= F0pcGOV_r_wo_a 
			replace shock_e		 	= F0pcGOV_e
			replace shock 			= F0pcGOV
			
			* LP regression
			xi: ivreg2 F`i'`lhsvar' shock_r_w_a shock shock_e   ///
			i.id i.Year `rhscontrols_r_w_a' `rhscontrols_r_wo_a' `rhscontrols_e' ///
			if ( F0`recession_id' > 0 & F0`recession_id'!=. ) | (F0`recession_id' < 0 & Alesina4 > 0 & Alesina4 !=. & F0`recession_id'!=.) | ( F0`recession_id' < 0 & Alesina4 <= 0 & Alesina4 !=. & F0`recession_id' !=. ), ///
			cluster(id) partial( i.id i.Year)  
			
			
			replace b_`lhsvar'_r_w_a  	= _b[shock_r_w_a] if _n == `i'+1
			replace se_`lhsvar'_r_w_a 	= _se[shock_r_w_a] if _n == `i'+1
			
			replace b_`lhsvar'_r_w_a_d  	= _b[recession_w_a] if _n == `i'+1
			replace se_`lhsvar'_r_w_a_d 	= _se[recession_w_a] if _n == `i'+1

			}
					
	}		


***********************Baseline IV LP graphs**********************************
		
	* time variable	
	cap gen periods = _n - 1 if _n <= `horizon' +1

	* zero line
	cap gen zero = 0 if _n <= `horizon' +1
	***** create confidence bands (in this case 95 and 68%) ****
	scalar sig1 = 0.05	 // specify significance level ~ 2 sd
	scalar sig2 = 0.10	 // specify significance level ~ 1 sd
	
	cap gen up_`lhsvar'_r_w_a  = .
	cap gen dn_`lhsvar'_r_w_a  = .
	cap gen up2_`lhsvar'_r_w_a = .
	cap gen dn2_`lhsvar'_r_w_a = .
	cap gen up_`lhsvar'_r_wo_a  = .
	cap gen dn_`lhsvar'_r_wo_a  = .
	cap gen up2_`lhsvar'_r_wo_a = .
	cap gen dn2_`lhsvar'_r_wo_a = .

	 gen up_`lhsvar'_r_w_a_d  = .
	 gen dn_`lhsvar'_r_w_a_d  = .
	 gen up2_`lhsvar'_r_w_a_d = .
	 gen dn2_`lhsvar'_r_w_a_d = .
	 gen up_`lhsvar'_r_wo_a_d  = .
	 gen dn_`lhsvar'_r_wo_a_d  = .
	 gen up2_`lhsvar'_r_wo_a_d = .
	 gen dn2_`lhsvar'_r_wo_a_d = .
	
	*confidence intervals
	replace up_`lhsvar'_r_w_a 	= b_`lhsvar'_r_w_a  + invnormal(1-sig1/2)*se_`lhsvar'_r_w_a  if _n <= (`horizon' + 1)
	replace dn_`lhsvar'_r_w_a 	= b_`lhsvar'_r_w_a  - invnormal(1-sig1/2)*se_`lhsvar'_r_w_a  if _n <= (`horizon' + 1)
	replace up2_`lhsvar'_r_w_a 	= b_`lhsvar'_r_w_a  + invnormal(1-sig2/2)*se_`lhsvar'_r_w_a  if _n <= (`horizon' + 1)
	replace dn2_`lhsvar'_r_w_a 	= b_`lhsvar'_r_w_a  - invnormal(1-sig2/2)*se_`lhsvar'_r_w_a  if _n <= (`horizon' + 1)

	replace up_`lhsvar'_r_wo_a	= b_`lhsvar'_r_wo_a  + invnormal(1-sig1/2)*se_`lhsvar'_r_wo_a  if _n <= (`horizon' + 1)
	replace dn_`lhsvar'_r_wo_a 	= b_`lhsvar'_r_wo_a  - invnormal(1-sig1/2)*se_`lhsvar'_r_wo_a  if _n <= (`horizon' + 1)
	replace up2_`lhsvar'_r_wo_a = b_`lhsvar'_r_wo_a  + invnormal(1-sig2/2)*se_`lhsvar'_r_wo_a  if _n <= (`horizon' + 1)
	replace dn2_`lhsvar'_r_wo_a = b_`lhsvar'_r_wo_a  - invnormal(1-sig2/2)*se_`lhsvar'_r_wo_a  if _n <= (`horizon' + 1)
	
	replace up_`lhsvar'_r_w_a_d 	= b_`lhsvar'_r_w_a_d  + invnormal(1-sig1/2)*se_`lhsvar'_r_w_a_d  if _n <= (`horizon' + 1)
	replace dn_`lhsvar'_r_w_a_d 	= b_`lhsvar'_r_w_a_d  - invnormal(1-sig1/2)*se_`lhsvar'_r_w_a_d  if _n <= (`horizon' + 1)
	replace up2_`lhsvar'_r_w_a_d 	= b_`lhsvar'_r_w_a_d  + invnormal(1-sig2/2)*se_`lhsvar'_r_w_a_d  if _n <= (`horizon' + 1)
	replace dn2_`lhsvar'_r_w_a_d 	= b_`lhsvar'_r_w_a_d  - invnormal(1-sig2/2)*se_`lhsvar'_r_w_a_d  if _n <= (`horizon' + 1)

	replace up_`lhsvar'_r_wo_a_d	= b_`lhsvar'_r_wo_a_d  + invnormal(1-sig1/2)*se_`lhsvar'_r_wo_a_d  if _n <= (`horizon' + 1)
	replace dn_`lhsvar'_r_wo_a_d 	= b_`lhsvar'_r_wo_a_d  - invnormal(1-sig1/2)*se_`lhsvar'_r_wo_a_d  if _n <= (`horizon' + 1)
	replace up2_`lhsvar'_r_wo_a_d 	= b_`lhsvar'_r_wo_a_d  + invnormal(1-sig2/2)*se_`lhsvar'_r_wo_a_d  if _n <= (`horizon' + 1)
	replace dn2_`lhsvar'_r_wo_a_d 	= b_`lhsvar'_r_wo_a_d  - invnormal(1-sig2/2)*se_`lhsvar'_r_wo_a_d  if _n <= (`horizon' + 1)
	
	* graphs
	** LPs
	if "`lhsvar'" == "Far_share" {
		twoway (rarea up_`lhsvar'_r_w_a dn_`lhsvar'_r_w_a periods, fcolor(gs12) lcolor(white) lpattern(solid)) ///
		(rarea up2_`lhsvar'_r_w_a dn2_`lhsvar'_r_w_a periods, fcolor(gs10) lcolor(white) lpattern(solid)) ///
		(line b_`lhsvar'_r_w_a periods, lcolor(blue) lpattern(solid) lwidth(thick)) /// 
		(line zero periods, lcolor(black)), scale(1.4) ///
		ytitle("p.p.") xtitle("Year") graphregion(color(white)) ///
		plotregion(color(white)) legend(off)
		
		graph export "$Fig\Fig11a`Italy'.pdf", replace
		
		twoway (rarea up_`lhsvar'_r_w_a_d dn_`lhsvar'_r_w_a_d periods, fcolor(gs12) lcolor(white) lpattern(solid))  ///
		(rarea up2_`lhsvar'_r_w_a_d dn2_`lhsvar'_r_w_a_d periods, fcolor(gs10) lcolor(white) lpattern(solid))  ///
		(line b_`lhsvar'_r_w_a_d periods, lcolor(blue) lpattern(solid) lwidth(thick)) ///
		(line zero periods, lcolor(black)),  ///
		scale(1.4) ytitle("p.p.") xtitle("Year") graphregion(color(white))  ///
		plotregion(color(white)) legend(off)
		
		graph export "$Fig\Fig11b`Italy'.pdf", replace
		
	}
	else if "`lhsvar'" == "Trust"  {
		twoway (rarea up_`lhsvar'_r_w_a dn_`lhsvar'_r_w_a periods, fcolor(gs12) lcolor(white) lpattern(solid)) ///
		(rarea up2_`lhsvar'_r_w_a dn2_`lhsvar'_r_w_a periods, fcolor(gs10) lcolor(white) lpattern(solid)) ///
		(line b_`lhsvar'_r_w_a periods, lcolor(blue) lpattern(solid) lwidth(thick)) /// 
		(line zero periods, lcolor(black)), scale(1.4) ///
		ytitle("p.p.") xtitle("Year") graphregion(color(white)) ///
		plotregion(color(white)) legend(off)
		
		graph export "$Fig\Fig11c`Italy'.pdf", replace
		
		twoway (rarea up_`lhsvar'_r_w_a_d dn_`lhsvar'_r_w_a_d periods, fcolor(gs12) lcolor(white) lpattern(solid))  ///
		(rarea up2_`lhsvar'_r_w_a_d dn2_`lhsvar'_r_w_a_d periods, fcolor(gs10) lcolor(white) lpattern(solid))  ///
		(line b_`lhsvar'_r_w_a_d periods, lcolor(blue) lpattern(solid) lwidth(thick)) ///
		(line zero periods, lcolor(black)),  ///
		scale(1.4) ytitle("p.p.") xtitle("Year") graphregion(color(white))  ///
		plotregion(color(white)) legend(off)
		
		graph export "$Fig\Fig11d`Italy'.pdf", replace
		
	}


}

