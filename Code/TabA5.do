* Proxy for Government Spending at the Regional Level

/*Run this code to produce the results from Table A5*/

use "${hp}Data\Out\Data_Final_nuts2.dta", clear

* Adjusted non-market GVA with intermediate consumption at Nuts 2 - GOV
gen ln_GOV = ln(GOV)

* EUREGIO regional government spending series [2000-2010]
gen GOV_EUREGIO 	= govspend / GDP_deflator * 100
gen ln_GOV_EUREGIO 	= ln(GOV_EUREGIO)

* Year dummies
tabulate Year, gen(ydummy)

* Regressions
eststo: xtreg ln_GOV_EUREGIO ln_GOV, vce(cluster id)
global b_1: di %6.2fc _b[ln_GOV]
global se_1: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_1 = r(p)
glo star_1=cond(${p_1}<.01,"***",cond(${p_1}<.05,"**",cond(${p_1}<.1,"*","")))
local N=e(N)
global N_1: di %12.0fc `N'

eststo: xtreg ln_GOV_EUREGIO ln_GOV, vce(cluster id) fe
global b_2: di %6.2fc _b[ln_GOV]
global se_2: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_2 = r(p)
glo star_2=cond(${p_2}<.01,"***",cond(${p_2}<.05,"**",cond(${p_2}<.1,"*","")))
local N=e(N)
global N_2: di %12.0fc `N'

eststo: xtreg ln_GOV_EUREGIO ln_GOV ydummy*, vce(cluster id) fe
global b_3: di %6.2fc _b[ln_GOV]
global se_3: di %6.2fc _se[ln_GOV]
test ln_GOV=0
global p_3 = r(p)
glo star_3=cond(${p_3}<.01,"***",cond(${p_3}<.05,"**",cond(${p_3}<.1,"*","")))
local N=e(N)
global N_3: di %12.0fc `N'

* save values
texdoc init "$Tab\TableA5.tex", replace force
tex log \textit{G} & ${b_1}${star_1} & ${b_2}${star_2} & ${b_3}${star_3}   \\ 
tex  & (${se_1} ) & (${se_2} ) & (${se_3} )   \\  \addlinespace
tex Country FE & No & Yes & Yes \\
tex Time FE & No & No & Yes \\ 
tex \# Obs & ${N_1} & ${N_2} & ${N_3}   \\ \addlinespace \bottomrule \addlinespace

texdoc close
