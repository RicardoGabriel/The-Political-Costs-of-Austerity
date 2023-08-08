* Response of far vote share: robustness dropping one country at the time

*List of dependent variables
local lhsvarlist Far_share 
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

*to have the same sample when looking at real and political variables
drop if Far_share==.

* forward change of LHS variable electoral dependent variables
foreach var in `lhsvarlist' {
	forvalues i=0/`horizon' {
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
		gen F`i'`lhsvar'RHS = (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100)
		*(-1) because we want to analyze the impact of austerity: a drop in gov spending!
			}
}

********************************************************************************
*Step 2)					LOCAL PROJECTIONS - produce table directly to tex
********************************************************************************

foreach lhsvar in `lhsvarlist'   {/*LHS variable: `lhsvarlist' */
	
	local var pcGOV
	local rhscontrols`lhsvar' l(1/`MaxLPLags').F0`lhsvar' l(1/`MaxLPLags').F0pcGOVRHS  l(1/`MaxLPLags').F0pcGDP

	*variables to store the impulse response (vector of betas from the LP regressions) and standard errors
	cap gen b_`lhsvar'_iv  = .
	cap gen se_`lhsvar'_iv = .
	cap gen Fstat_`lhsvar'_iv = .

	
	*xi: ivreg2 F4`lhsvar' (F0`var'RHS  = `inst') ///
	*	`rhscontrols`lhsvar'' i.id i.Year,  ///
	*	cluster(id) partial(`rhscontrols`lhsvar'' i.id i.Year)
	*cap gen xsample=e(sample)
		
	*** Baseline LP table Using IV
	* One regression for each horizon of the response (0-4 years)
	forvalues i = 0/`horizon' {
		
		
		* LP regression	
		xi: ivreg2 F`i'`lhsvar' (F0`var'RHS  = `inst') ///
		`rhscontrols`lhsvar'' i.id i.Year,  ///
		cluster(id) partial(`rhscontrols`lhsvar'' i.id i.Year)
	
		
		*save coefs
		global b_`i': di %6.2fc _b[F0`var'RHS]
		global se_`i': di %6.2fc _se[F0`var'RHS]
		
		test F0`var'RHS=0
		global p_`lhsvar'_`i' = r(p)
		glo star_`i'=cond(${p_`lhsvar'_`i'}<.01,"***",cond(${p_`lhsvar'_`i'}<.05,"**",cond(${p_`lhsvar'_`i'}<.1,"*","")))
		

	}
}

texdoc init "$hp\Outputs\Tables\TableC3.tex", replace force
tex Baseline & ${b_0}${star_0} & ${b_1}${star_1}  & ${b_2}${star_2} & ${b_3}${star_3} & ${b_4}${star_4}  \\
tex	& (${se_0} ) & (${se_1} ) & (${se_2} ) & (${se_3} ) & (${se_4} )   \\ 
tex	\# Obs  & ${N_0}& ${N_1} & ${N_2} & ${N_3} & ${N_4}   \\  \addlinespace \midrule \addlinespace
texdoc close

****************************
* Rob check
****************************
	
levelsof Country, local(clist)
foreach c in `clist'{
	
	foreach lhsvar in `lhsvarlist' {/*LHS variable: `lhsvarlist' */

		local rhscontrols`lhsvar' l(1/`MaxLPLags').F0`lhsvar' l(1/`MaxLPLags').F0pcGOVRHS  l(1/`MaxLPLags').F0pcGDP

		*variables to store the impulse response (vector of betas from the LP regressions) and standard errors
		cap gen b_`lhsvar'_iv  = .
		cap gen se_`lhsvar'_iv = .
		cap gen Fstat_`lhsvar'_iv = .
		
		local var pcGOV 

		*** Baseline LP table Using IV
		* One regression for each horizon of the response (0-4 years)
		forvalues i = 0/`horizon' {
		
		
			* LP regression	
			xi: ivreg2 F`i'`lhsvar' (F0`var'RHS  = `inst') ///
				`rhscontrols`lhsvar'' i.id i.Year if Country != "`c'", ///
				cluster(id) partial(`rhscontrols`lhsvar'' i.id i.Year)
			
			global b_`c'_`i': di %6.2fc _b[F0`var'RHS ]
			global se_`c'_`i': di %6.2fc _se[F0`var'RHS ]
			
			test F0`var'RHS=0
			global p_`c'_`i'= r(p)
			glo star_`c'_`i'=cond(${p_`c'_`i'}<.01,"***",cond(${p_`c'_`i'}<.05,"**",cond(${p_`c'_`i'}<.1,"*","")))
			
			local N=e(N)
			global N_`c'_`i': di %12.0fc `N'

		
		}
	}

	texdoc init "$hp\Outputs\Tables\TableC3.tex", append force
	tex `c' & ${b_`c'_0}${star_`c'_0} & ${b_`c'_1}${star_`c'_1}  & ${b_`c'_2}${star_`c'_2} & ${b_`c'_3}${star_`c'_3} & ${b_`c'_4}${star_`c'_4} \\
	tex	& (${se_`c'_0} ) & (${se_`c'_1} )  & (${se_`c'_2} ) & (${se_`c'_3} ) & (${se_`c'_4} ) \\ 
	tex	\# Obs & ${N_`c'_0}& ${N_`c'_1} & ${N_`c'_2} & ${N_`c'_3} & ${N_`c'_4}   \\ \addlinespace
	texdoc close
}
