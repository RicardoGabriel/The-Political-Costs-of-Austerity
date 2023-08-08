* Proxy for Government Spending at the National Level
 
/*Run this code to produce the results from Table A4*/



* necessary programs
*ssc install boottest

* decide how many reps the bootstrap estimation should use (standard is 1000)
local reps 			= 9999
local confidence 	= 95

use "${hp}Data\Out\Real\Data_Analysis_Nuts0.dta", clear

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

* ID dummies
tabulate cid, gen(cdummy)

preserve
* Panel A
* To have a balance panel keep years for each there is available AMECO data (1995-2015)
keep if inrange(Year,1995,2015)
** in logs
eststo: reg ln_GOV_AMECO ln_GOV, cluster(id)
global b_1: di %6.2fc _b[ln_GOV]
boottest ln_GOV, reps(`reps') boot(wild) level(`confidence') cluster(id) bootcluster(id) nograph
mat CI = r(CI)
global se_1: di %6.2fc CI[1,1]
global se_12: di %6.2fc CI[1,2]
global p_1: di %6.3fc r(p)
glo star_1=""
local N=e(N)
global N_1: di %12.0fc `N'
				
eststo: reg ln_GOV_AMECO ln_GOV cdummy1-cdummy8, cluster(id)
global b_2: di %6.2fc _b[ln_GOV]
boottest ln_GOV, reps(`reps') boot(wild) level(`confidence') cluster(id) bootcluster(id) nograph
mat CI = r(CI)
global se_2: di %6.2fc CI[1,1]
global se_22: di %6.2fc CI[1,2]
global p_2: di %6.3fc r(p)
glo star_2=""
local N=e(N)
global N_2: di %12.0fc `N'

eststo: reg ln_GOV_AMECO ln_GOV cdummy1-cdummy8 ydummy1-ydummy36, cluster(id)
global b_3: di %6.2fc _b[ln_GOV]
boottest ln_GOV, reps(`reps') boot(wild) level(`confidence') cluster(id) bootcluster(id) nograph
mat CI = r(CI)
global se_3: di %6.2fc CI[1,1]
global se_32: di %6.2fc CI[1,2]
global p_3: di %6.3fc r(p)
glo star_3=""
local N=e(N)
global N_3: di %12.0fc `N'

* save values
texdoc init "$Tab\TableA4.tex", replace force
tex \textbf{Panel A: AMECO - Balanced panel: 1995-2015} \\
tex log \textit{G} & ${b_1}${star_1} & ${b_2}${star_2} & ${b_3}${star_3}   \\
tex & (${p_1}) & (${p_2}) & (${p_3})   \\
tex & [${se_1},${se_12}] & [${se_2},${se_22}] & [${se_3},${se_32}]   \\ 
tex \# Obs & ${N_1} & ${N_2} & ${N_3}   \\ \addlinespace \midrule \addlinespace
texdoc close
restore

* Panel B
eststo: reg ln_GOV_AMECO ln_GOV, cluster(id)
global b_1: di %6.2fc _b[ln_GOV]
boottest ln_GOV=0, reps(`reps') boot(wild) level(`confidence') cluster(id) bootcluster(id) nograph
mat CI = r(CI)
global se_1: di %6.2fc CI[1,1]
global se_12: di %6.2fc CI[1,2]
global p_1: di %6.3fc r(p)
*glo star_1=cond(${p_1}<.01,"***",cond(${p_1}<.05,"**",cond(${p_1}<.1,"*","")))
local N=e(N)
global N_1: di %12.0fc `N'
				
eststo: reg ln_GOV_AMECO ln_GOV cdummy1-cdummy8, cluster(id)
global b_2: di %6.2fc _b[ln_GOV]
boottest ln_GOV=0, reps(`reps') boot(wild) level(`confidence') cluster(id) bootcluster(id) nograph
mat CI = r(CI)
global se_2: di %6.2fc CI[1,1]
global se_22: di %6.2fc CI[1,2]
global p_2: di %6.3fc r(p)
*glo star_2=cond(${p_2}<.01,"***",cond(${p_2}<.05,"**",cond(${p_2}<.1,"*","")))
local N=e(N)
global N_2: di %12.0fc `N'

eststo: reg ln_GOV_AMECO ln_GOV cdummy1-cdummy8 ydummy1-ydummy36, cluster(id)
global b_3: di %6.2fc _b[ln_GOV]
boottest ln_GOV=0, reps(`reps') boot(wild) level(`confidence') cluster(id) bootcluster(id) nograph
mat CI = r(CI)
global se_3: di %6.2fc CI[1,1]
global se_32: di %6.2fc CI[1,2]
global p_3: di %6.3fc r(p)
*glo star_3=cond(${p_3}<.01,"***",cond(${p_3}<.05,"**",cond(${p_3}<.1,"*","")))
local N=e(N)
global N_3: di %12.0fc `N'

* save values
texdoc init "$Tab\TableA4.tex", append force
tex \textbf{Panel B: AMECO - Unbalanced panel} \\
tex log \textit{G} & ${b_1}${star_1} & ${b_2}${star_2} & ${b_3}${star_3}   \\ 
tex & (${p_1}) & (${p_2}) & (${p_3})   \\
tex & [${se_1},${se_12}] & [${se_2},${se_22}] & [${se_3},${se_32}]   \\ 
tex  \# Obs & ${N_1} & ${N_2} & ${N_3}   \\ \addlinespace \midrule \addlinespace
tex Country FE & No & Yes & Yes \\
tex Time FE & No & No & Yes \\ \addlinespace \bottomrule \addlinespace
texdoc close
