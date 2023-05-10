					*** 12_4_Do_Tab3.do ***
 
*Authors: Ricardo Duque Gabriel, Mathias Klein, and Ana Sofia Pessoa
*Start Date: 30/05/2020
*Last Update: 16/01/2023

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

*to have the same sample when looking at real and political variables
drop if Far_share==.
********************************************************************************
*Step 1)					DATA PREPARATION
********************************************************************************
*********************************************
***** 	 GENERATE STATE VARIABLES   	*****
*********************************************
local state = "core"
local low "Core"
local high "Periphery"

*forward changes for control variables
foreach lhsvar in pcGDP{	
forvalues i = 0/`horizon'{	
	gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.`lhsvar' *100
	label var F`i'`lhsvar' "Forward `i' year change in `lhsvar', percent %"		
}
}


********************* Left vs Right **************************************

* Generated in file Incumbents.do	
	
*********************************************
***** 	 GENERATE LHS VARIABLES 	*****
*********************************************
*List of dependent variables
local lhsvarlist Far_share 
local lhsrealvarlist pcGDP

* forward change of LHS variable electoral dependent variables
foreach var in `lhsvarlist' {
	*gen log`var' = log(1+(100*`var'))
	forvalues i=0/`horizon' {
		*qui gen F`i'`var' = 100*(F`i'.log`var' - L.log`var')
		*label var F`i'`var' "Forward `i' year change in `var', percent %"
		qui gen F`i'`var' 		= 100*(F`i'.`var' - L.`var')
		qui gen F`i'`var'_low 	= 100*(F`i'.`var' - L.`var') * `state'
		qui gen F`i'`var'_high 	= 100*(F`i'.`var' - L.`var') * (1 - `state')
	}
}		

*forward change of LHS real variables in growth rates (%)
foreach lhsvar in `lhsrealvarlist' {	
	forvalues i = 0/`horizon'{
		*gen F`i'`lhsvar'	 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100
		gen F`i'`lhsvar'_low 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100 * `state'
		gen F`i'`lhsvar'_high 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100 * (1 - `state')
	}
}

*forward change of LHS variable scaled by lagged pcGDP
** State dependent variables
cap gen Alesina4_low = Alesina4 * `state'
cap gen Alesina4_high= Alesina4 * (1 - `state')

foreach lhsvar in pcGOV {
	forvalues i = 0/`horizon' {
		cap gen F`i'`lhsvar'    	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100)  
		cap gen F`i'`lhsvar'_low 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100) * `state'
		cap gen F`i'`lhsvar'_high 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100) * (1 - `state')
	}
}


*******************************************************************************
*** Multipliers
********************************************************************************
cap gen shock			= .
cap gen shock_low 		= .
cap gen shock_high      = .
lab var shock_low "Multiplier `low'"
lab var shock_high "Multiplier `high'"

foreach lhsvar in `lhsvarlist' {/*LHS variable*/

	foreach var in pcGOV{	
		
		* controls in LP regression
		local rhscontrols_high l(1/`MaxLPLags').F0pcGOV_high l(1/`MaxLPLags').F0pcGDP_high l(1/`MaxLPLags').F0`lhsvar'_high `state' 
		local rhscontrols_low l(1/`MaxLPLags').F0pcGOV_low l(1/`MaxLPLags').F0pcGDP_low l(1/`MaxLPLags').F0`lhsvar'_low `state'

		
		*** Baseline LP table Using IV
		* One regression for each horizon of the response (0-4 years)
		forvalues i = 0/`horizon' {
			local ord = `i' + 1
			replace shock    	= F0pcGOV
			replace shock_low 	= F0pcGOV_low
			replace shock_high 	= F0pcGOV_high
			
			* LP regression
			xi: ivreg2 F`i'`lhsvar' (shock_low shock_high  = Alesina4_low Alesina4_high) ///
			`rhscontrols_low' `rhscontrols_high' i.id i.Year,  ///
			cluster(id) partial(`rhscontrols_low' `rhscontrols_high' i.id i.Year)
			
						** Store Coeffs
			*coefficients and SE
			global b_`i'_low: di %6.2fc _b[shock_low]
			global se_`i'_low: di %6.2fc _se[shock_low]
			global b_`i'_high: di %6.2fc _b[shock_high]
			global se_`i'_high: di %6.2fc _se[shock_high]			

			
			*stars
			test shock_low=0
			global p_`i'_low= r(p)
			glo star_`i'_low = cond(${p_`i'_low}<.01,"***",cond(${p_`i'_low}<.05,"**",cond(${p_`i'_low}<.1,"*","")))
			
			test shock_high=0
			global p_`i'_high= r(p)
			glo star_`i'_high = cond(${p_`i'_high}<.01,"***",cond(${p_`i'_high}<.05,"**",cond(${p_`i'_high}<.1,"*","")))
			
			*Nr observations
			local N=e(N)
			global N_`i': di %12.0fc `N'
			
			*Test HAC equal coefficients
			test shock_low = shock_high
			global HAC_`i': di %6.2fc r(p)			
			
			*Test AR equal coefficients - run AR test as in Ramey and Zubairy (2018) JPE
			weakiv ivreg2 F`i'`lhsvar' (shock shock_high  = Alesina4_low Alesina4_high) ///
			`rhscontrols_low' `rhscontrols_high' i.id i.Year,  ///
			cluster(id) level(95) gridpoints(100) strong(shock)
			
			global AR_`i': di %12.2fc e(ar_p)
	
		}
	}		
}


texdoc init "$Tab\TableR3`Italy'.tex", append force
tex \multicolumn{6}{l}{\textbf{Panel D: Core vs Periphery}} \\
tex Core & ${b_0_low}${star_0_low} & ${b_1_low}${star_1_low}  & ${b_2_low}${star_2_low} & ${b_3_low}${star_3_low} & ${b_4_low}${star_4_low}  \\
tex	& (${se_0_low} ) & (${se_1_low} ) & (${se_2_low} ) & (${se_3_low} ) & (${se_4_low} )   \\ \addlinespace 
tex Periphery & ${b_0_high}${star_0_high} & ${b_1_high}${star_1_high}  & ${b_2_high}${star_2_high} & ${b_3_high}${star_3_high} & ${b_4_high}${star_4_high}  \\
tex	& (${se_0_high} ) & (${se_1_high} ) & (${se_2_high} ) & (${se_3_high} ) & (${se_4_high} )   \\
tex	HAC Test  & ${HAC_0}& ${HAC_1} & ${HAC_2} & ${HAC_3} & ${HAC_4}   \\  
tex	AR Test  & ${AR_0}& ${AR_1} & ${AR_2} & ${AR_3} & ${AR_4}   \\  \addlinespace \bottomrule  
texdoc close	
