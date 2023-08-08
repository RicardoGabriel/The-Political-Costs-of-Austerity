* Forecast error variance decomposition

*Code of FEVD exercise following paper by Born, Müller, Pfeifer, and Wellmann (2020)

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

*List of dependent variables

local lhsvarlist Far_share Far_Left_share Far_Right_share   
local lhsrealvarlist pcGDP Emp pcGOV 

* forward change of LHS variable electoral dependent variables
foreach var in `lhsvarlist' {
	forvalues i=0/`horizon' {
		qui gen F`i'`var' = 100*(F`i'.`var' - L.`var')
		label var F`i'`var' "Forward `i' year change in `var', pp"
	}
}		

*forward change of LHS real variables in growth rates (%)
foreach lhsvar in `lhsrealvarlist'{	
	forvalues i = 0/`horizon'{
		gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.`lhsvar' *100
		label var F`i'`lhsvar' "Forward `i' year change in `lhsvar', percent %"
	}
}

*forward change of RHS variable in growth rates (%)
foreach lhsvar in pcGOV {
	forvalues i = 0/`horizon' {
		gen F`i'`lhsvar'RHS = (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (-100)
		*(-100) because we want to analyze the impact of austerity: a drop in gov spending!
		label var F`i'`lhsvar' "Forward `i' year change in `lhsvar' * (-1) (%)"
	}
}

********************************************************************************
*Step 2)					LOCAL PROJECTIONS
********************************************************************************

* controls in LP regression
foreach lhsvar in `lhsrealvarlist' pcGDP Emp{
	if "`lhsvar'" == "pcGOV"{
		local rhscontrols`lhsvar' l(1/`MaxLPLags').F0`lhsvar'
	}
	else{
		local rhscontrols`lhsvar' l(1/`MaxLPLags').F0pcGOVRHS l(1/`MaxLPLags').F0`lhsvar'
	}
}
foreach lhsvar in `lhsvarlist' {
	local rhscontrols`lhsvar' l(1/`MaxLPLags').F0pcGOVRHS l(1/`MaxLPLags').F0pcGDP l(1/`MaxLPLags').F0`lhsvar'
}


foreach lhsvar in `lhsvarlist' {
	foreach var in pcGOV {
	
		***********************************************************************
		*** 2.1) Computing FE and Shocks
		***********************************************************************
		
		xtreg F0`var'RHS `inst' `rhscontrols`lhsvar'' i.id 
		predict resid if e(sample)==1, xb
		rename resid resid_`var'
	
		forvalues i = 0/`horizon' {
			xtreg F`i'`lhsvar' resid_`var' `rhscontrols`lhsvar'' i.id
			predict fe_`i'`lhsvar' if e(sample)==1, ue
		}
	
		************************************************************************
		*** 2.2) Forecast error decomposition
		************************************************************************

		* time variable	
		cap gen period = _n - 1 if _n <= `horizon' +1
		
		* decomposition of the forecast error variance
		cap gen decomposition_`lhsvar' = .


		reg fe_0`lhsvar' resid_`var', nocons
		local rsquared = e(r2)*100
		global b_`lhsvar'_0: di %6.1fc `rsquared'
				
		reg fe_1`lhsvar' resid_`var' F.resid_`var' , nocons
		local rsquared = e(r2)*100
		global b_`lhsvar'_1: di %6.1fc `rsquared'

		reg fe_2`lhsvar' resid_`var' F.resid_`var' F2.resid_`var' , nocons
		local rsquared = e(r2)*100
		global b_`lhsvar'_2: di %6.1fc `rsquared'

		reg fe_3`lhsvar' resid_`var' F.resid_`var' F2.resid_`var' F3.resid_`var' , nocons
		local rsquared = e(r2)*100
		global b_`lhsvar'_3: di %6.1fc `rsquared'

		reg fe_4`lhsvar' resid_`var' F.resid_`var' F2.resid_`var' F3.resid_`var' F4.resid_`var' , nocons
		local rsquared = e(r2)*100
		global b_`lhsvar'_4: di %6.1fc `rsquared'
	
		drop resid_*
	}
}


*save table
texdoc init "$Tab\Table1.tex", replace force
tex 0 & ${b_Far_share_0} \% & ${b_Far_Left_share_0} \% & ${b_Far_Right_share_0} \% \\ \addlinespace
tex 1 & ${b_Far_share_1} \% & ${b_Far_Left_share_1} \% & ${b_Far_Right_share_1} \% \\ \addlinespace
tex 2 & ${b_Far_share_2} \% & ${b_Far_Left_share_2} \% & ${b_Far_Right_share_2} \% \\ \addlinespace
tex 3 & ${b_Far_share_3} \% & ${b_Far_Left_share_3} \% & ${b_Far_Right_share_3} \% \\ \addlinespace
tex 4 & ${b_Far_share_4} \% & ${b_Far_Left_share_4} \% & ${b_Far_Right_share_4} \% \\ \addlinespace \bottomrule
texdoc close

	


