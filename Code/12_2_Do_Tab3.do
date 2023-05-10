				*** 10_2_Do_Tab3.do ***

*Authors: Ricardo Duque Gabriel, Mathias Klein, and Ana Sofia Pessoa
*Start Date: 04/12/2020
*Last Update: 04/12/2020

* number of lags
local MaxLPLags 2
* horizon
local horizon 4
*instrument 
local inst = "$inst"

use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear
merge m:1 Nuts_id using "${hp}Data\Eurostat\Area.dta"

sort id Year

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
local state = "urban"
local urban "Urban"
local rural "Rural"

gen density = Population /Area

*defining urban state
cap drop urban 
gen urban = 0
levelsof cid, local(clist)
foreach c in `clist'{
	levelsof Year, local(ylist)
	foreach y in `ylist'{
		sum density if cid == `c' & Year==`y', d
		replace urban = 1 if density > r(p50) & cid == `c' & Year==`y'
	}
}
	
	 
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
		cap drop F`i'`var'*
		qui gen F`i'`var' 		= 100*(F`i'.`var' - L.`var')
		qui gen F`i'`var'_urban 	= 100*(F`i'.`var' - L.`var') * `state'
		qui gen F`i'`var'_rural 	= 100*(F`i'.`var' - L.`var') * (1 - `state')
	}
}		

*forward change of LHS real variables in growth rates (%)
foreach lhsvar in `lhsrealvarlist' {	
	forvalues i = 0/`horizon'{
		cap drop F`i'`lhsvar'*
		gen F`i'`lhsvar'	 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100
		gen F`i'`lhsvar'_urban 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100 * `state'
		gen F`i'`lhsvar'_rural 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGDP *100 * (1 - `state')
	}
}

*forward change of LHS variable scaled by lagged pcGDP
** State dependent variables
cap drop Alesina4_*
cap gen Alesina4_urban = Alesina4 * `state'
cap gen Alesina4_rural= Alesina4 * (1 - `state')

foreach lhsvar in pcGOV {
	forvalues i = 0/`horizon' {
		cap gen F`i'`lhsvar'     	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100)  
		cap gen F`i'`lhsvar'_urban 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100) * `state'
		cap gen F`i'`lhsvar'_rural 	= (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100) * (1 - `state')
	}
}
*******************************************************************************
*** Local Projections
********************************************************************************
cap gen shock			= .
cap gen shock_urban 	= .
cap gen shock_rural     = .
lab var shock_urban "LP `urban'"
lab var shock_rural "LP `rural'"

foreach lhsvar in `lhsvarlist' {/*LHS variable*/
	
	foreach var in pcGOV{	
		
		* controls in LP regression
		local rhscontrols_rural l(1/`MaxLPLags').F0Far_share_rural l(1/`MaxLPLags').F0pcGOV_rural l(1/`MaxLPLags').F0pcGDP_rural `state'
		local rhscontrols_urban l(1/`MaxLPLags').F0Far_share_rural l(1/`MaxLPLags').F0pcGOV_urban l(1/`MaxLPLags').F0pcGDP_urban `state'
		
		
		*** Baseline LP table Using IV
		* One regression for each horizon of the response (0-4 years)
		forvalues i = 0/`horizon' {
			local ord = `i' + 1
			replace shock    		= F0pcGOV
			replace shock_urban 	= F0pcGOV_urban
			replace shock_rural 	= F0pcGOV_rural
			
			* LP regression
			xi: ivreg2 F`i'`lhsvar' (shock_urban shock_rural  = Alesina4_urban Alesina4_rural) ///
			`rhscontrols_urban' `rhscontrols_rural' i.id i.Year,  ///
			cluster(id) partial(`rhscontrols_urban' `rhscontrols_rural' i.id i.Year)
			

			** Store Coeffs
			*coefficients and SE
			global b_`i'_urban: di %6.2fc _b[shock_urban]
			global se_`i'_urban: di %6.2fc _se[shock_urban]
			global b_`i'_rural: di %6.2fc _b[shock_rural]
			global se_`i'_rural: di %6.2fc _se[shock_rural]			

			
			*stars
			test shock_urban=0
			global p_`i'_urban= r(p)
			glo star_`i'_urban = cond(${p_`i'_urban}<.01,"***",cond(${p_`i'_urban}<.05,"**",cond(${p_`i'_urban}<.1,"*","")))
			
			test shock_rural=0
			global p_`i'_rural= r(p)
			glo star_`i'_rural = cond(${p_`i'_rural}<.01,"***",cond(${p_`i'_rural}<.05,"**",cond(${p_`i'_rural}<.1,"*","")))
			
			*Nr observations
			local N=e(N)
			global N_`i': di %12.0fc `N'
			
			*Test HAC equal coefficients
			test shock_urban = shock_rural
			global HAC_`i': di %6.2fc r(p)			
			
			*Test AR equal coefficients - run AR test as in Ramey and Zubairy (2018) JPE
			weakiv ivreg2 F`i'`lhsvar' (shock shock_urban  = Alesina4_urban Alesina4_rural) ///
			`rhscontrols_urban' `rhscontrols_rural' i.id i.Year,  ///
			cluster(id) level(95) gridpoints(100) strong(shock)
			
			global AR_`i': di %12.2fc e(ar_p)
			
			
		}
	}		
}

texdoc init "$Tab\Table3`Italy'.tex", append force
tex \multicolumn{6}{l}{\textbf{Panel B: rural vs urban}} \\
tex Rural & ${b_0_rural}${star_0_rural} & ${b_1_rural}${star_1_rural}  & ${b_2_rural}${star_2_rural} & ${b_3_rural}${star_3_rural} & ${b_4_rural}${star_4_rural}  \\
tex	& (${se_0_rural} ) & (${se_1_rural} ) & (${se_2_rural} ) & (${se_3_rural} ) & (${se_4_rural} )   \\
tex Urban & ${b_0_urban}${star_0_urban} & ${b_1_urban}${star_1_urban}  & ${b_2_urban}${star_2_urban} & ${b_3_urban}${star_3_urban} & ${b_4_urban}${star_4_urban}  \\
tex	& (${se_0_urban} ) & (${se_1_urban} ) & (${se_2_urban} ) & (${se_3_urban} ) & (${se_4_urban} )   \\ \addlinespace 
tex	HAC Test  & ${HAC_0}& ${HAC_1} & ${HAC_2} & ${HAC_3} & ${HAC_4}   \\  
tex	AR Test  & ${AR_0}& ${AR_1} & ${AR_2} & ${AR_3} & ${AR_4}   \\  \addlinespace \midrule \addlinespace 
texdoc close	
