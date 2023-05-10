					*** A2_Table_Corr.do ***
 
/*Run this code to produce the results from Table A4*/


use "${hp}\Outputs\Data_aux\Data_Analysis_Nuts0.dta", clear

local Italy = "$noItaly"
if "`Italy'" == "_noItaly"{
	drop if cid == 5
}


keep if inrange(Year,1980,2015)

* Adjusted non-market GVA with intermediate consumption at Nuts 0 - GOV_nat
drop GOV
cap rename GOV_nat GOV
gen ln_GOV = ln(GOV)

* AMECO government spending series
gen GOV_AMECO 	= Gov_Spending_AMECO * GDP / 100
gen ln_GOV_AMECO= ln(GOV_AMECO)

* Year dummies
tabulate Year, gen(ydummy)

preserve
* Panel A
* To have a balance panel keep years for each there is available AMECO data (1995-2015)
keep if inrange(Year,1995,2015)
** in logs
eststo: xtreg ln_GOV_AMECO ln_GOV, vce(cluster id)
global b_1: di %6.2fc _b[ln_GOV]
global se_1: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_1 = r(p)
glo star_1=cond(${p_1}<.01,"***",cond(${p_1}<.05,"**",cond(${p_1}<.1,"*","")))
local N=e(N)
global N_1: di %12.0fc `N'
				
eststo: xtreg ln_GOV_AMECO ln_GOV, vce(cluster id) fe
global b_2: di %6.2fc _b[ln_GOV]
global se_2: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_2 = r(p)
glo star_2=cond(${p_2}<.01,"***",cond(${p_2}<.05,"**",cond(${p_2}<.1,"*","")))
local N=e(N)
global N_2: di %12.0fc `N'

eststo: xtreg ln_GOV_AMECO ln_GOV ydummy*, vce(cluster id) fe
global b_3: di %6.2fc _b[ln_GOV]
global se_3: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_3 = r(p)
glo star_3=cond(${p_3}<.01,"***",cond(${p_3}<.05,"**",cond(${p_3}<.1,"*","")))
local N=e(N)
global N_3: di %12.0fc `N'

* save values
texdoc init "$hp\Outputs\Tab\TableA4`Italy'.tex", replace force
tex \textbf{Panel A: AMECO - Balanced panel: 1995-2015} \\
tex log \textit{G} & ${b_1}${star_1} & ${b_2}${star_2} & ${b_3}${star_3}   \\ 
tex & (${se_1} ) & (${se_2} ) & (${se_3} )   \\ 
tex \# Obs & ${N_1} & ${N_2} & ${N_3}   \\ \addlinespace \midrule \addlinespace
texdoc close
restore

* Panel B
** in logs
eststo: xtreg ln_GOV_AMECO ln_GOV, vce(cluster id)
global b_1: di %6.2fc _b[ln_GOV]
global se_1: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_1 = r(p)
glo star_1=cond(${p_1}<.01,"***",cond(${p_1}<.05,"**",cond(${p_1}<.1,"*","")))
local N=e(N)
global N_1: di %12.0fc `N'
				
eststo: xtreg ln_GOV_AMECO ln_GOV, vce(cluster id) fe
global b_2: di %6.2fc _b[ln_GOV]
global se_2: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_2 = r(p)
glo star_2=cond(${p_2}<.01,"***",cond(${p_2}<.05,"**",cond(${p_2}<.1,"*","")))
local N=e(N)
global N_2: di %12.0fc `N'

eststo: xtreg ln_GOV_AMECO ln_GOV ydummy*, vce(cluster id) fe
global b_3: di %6.2fc _b[ln_GOV]
global se_3: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_3 = r(p)
glo star_3=cond(${p_3}<.01,"***",cond(${p_3}<.05,"**",cond(${p_3}<.1,"*","")))
local N=e(N)
global N_3: di %12.0fc `N'

* save values
texdoc init "$hp\Outputs\Tab\TableA4`Italy'.tex", append force
tex \textbf{Panel B: AMECO - Unbalanced panel} \\
tex log \textit{G} & ${b_1}${star_1} & ${b_2}${star_2} & ${b_3}${star_3}   \\ 
tex  & (${se_1} ) & (${se_2} ) & (${se_3} )   \\ 
tex  \# Obs & ${N_1} & ${N_2} & ${N_3}   \\ \addlinespace \midrule \addlinespace
tex Country FE & No & Yes & Yes \\
tex Time FE & No & No & Yes \\ \addlinespace \bottomrule \addlinespace
texdoc close
