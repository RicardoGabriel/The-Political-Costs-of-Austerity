				*** 6_8_Tab2.do ***

* Excluding capitals				
				
*Authors: Ricardo Duque Gabriel, Mathias Klein, and Ana Sofia Pessoa
*Start Date: 04/12/2020
*Last Update: 16/1/2023


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
local lhsvarlist Far_share // For the rob checks we only use total far share 


* forward change of LHS variable electoral dependent variables
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
foreach lhsvar in pcGDP{	
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


***********************************************************
* Variable for Capitals - not used so far
***********************************************************
preserve
gen capital = .
replace capital = 1 if Nuts_id == "AT13" | Nuts_id == "DE30" | ///
Nuts_id == "ES30" | Nuts_id == "FI1B" | Nuts_id == "FR10" | ///
Nuts_id == "ITI4" | Nuts_id == "PT17" | Nuts_id == "SE01"
drop if capital == 1
drop capital
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

foreach lhsvar in `lhsvarlist' {/*LHS variable: `lhsvarlist' */

	*variables to store the impulse response (vector of betas from the LP regressions) and standard errors
	cap gen b_`lhsvar'_iv  = .
	cap gen se_`lhsvar'_iv = .
	cap gen Fstat_`lhsvar'_iv = .
	
	foreach var in pcGOV {
		
		*** Baseline LP table Using IV
		* One regression for each horizon of the response (0-4 years)
		forvalues i = 0/`horizon' {
			local ord = `i' + 1 			// ord='i'+1 in ivreg2 is equivalent to ord='i' in xtscc (check "help ivreg2")
			if (("`lhsvar'" == "pcGOV") & `i' ==0){
				local ord = 0
			}
			
			
			* LP regression	
			xi: ivreg2 F`i'`lhsvar' (F0`var'RHS  = `inst') ///
			`rhscontrols`lhsvar'' i.id i.Year,  ///
			cluster(id) partial(`rhscontrols`lhsvar'' i.id i.Year)
			cap gen xsample=e(sample)
			
			
		*save coefs
		global b_`i': di %6.2fc _b[F0`var'RHS]
		global se_`i': di %6.2fc _se[F0`var'RHS]
		global N_`i' = e(N)
		
		test F0`var'RHS=0
		global p_`lhsvar'_`i' = r(p)
		glo star_`i'=cond(${p_`lhsvar'_`i'}<.01,"***",cond(${p_`lhsvar'_`i'}<.05,"**",cond(${p_`lhsvar'_`i'}<.1,"*","")))
		
		}

	}
}


texdoc init "$Tab\Table2.tex", append force
tex (8) Excluding capitals regions & ${b_0}${star_0} & ${b_1}${star_1}  & ${b_2}${star_2} & ${b_3}${star_3} & ${b_4}${star_4}  \\
tex	& (${se_0} ) & (${se_1} ) & (${se_2} ) & (${se_3} ) & (${se_4} )   \\ 
tex	\# Obs  & ${N_0}& ${N_1} & ${N_2} & ${N_3} & ${N_4}   \\  \addlinespace 
texdoc close

