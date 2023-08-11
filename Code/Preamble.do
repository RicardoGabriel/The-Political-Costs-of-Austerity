/*
Data preparation of IMF shocks.
*/

do Paths

********************************************************************************
* Preamble - Data Preparation of Austerity Shocks (Bartik Shift part)
********************************************************************************

** Alesina Shocks (values in % gdp t-1)
import excel "$hp\Data\Out\Real\Alesina.xlsx", sheet("Folha1") firstrow clear 

merge 1:1 Year Country using "$hp\Data\Out\Real\Data_IMFShocks_Klein.dta"
drop _merge

keep if Country == "Austria" | ///
	Country == "Finland" | Country == "France" | ///
	Country == "Germany" | Country == "Italy" |  ///
	Country == "Portugal" |  Country == "Spain" | Country == "Sweden" 

	*correlations here
	corr IMF A*

save "$hp\Data\Out\Real\Data_IMFShocks", replace




********************************************************************************
* Preamble - Bartik Instrument Construction (Share Part)
********************************************************************************

* Upload data
use "${hp}Data\Out\Real\Data_Real.dta", clear



*gen Bartik share (Full Sample - per capita)
local start = 1980
local end = 2014
bysort id: egen temp1 = mean(pcGOV_baseline) if Year <= `end' & Year >= `start'
bysort id: egen temp2 = mean(temp1) if Year >= `start' 
gen avrcapgovspend = temp2
	la var avrcapgovspend "average regional per capita gov. spendings"
bysort id: egen temp3 = mean(pcGOV_nat) if Year <= `end' & Year >= `start'
bysort id: egen temp4 = mean(temp3) if Year >= `start'
gen avrcapgovspend_nat = temp4
	la var avrcapgovspend_nat "average national per capita gov. spendings"
drop temp*
tsset id Year
gen fracmil2 = avrcapgovspend/avrcapgovspend_nat
	la var fracmil2 "% of regional average per capita gov. spendings"
drop avrcapgovspend avrcapgovspend_nat

gen fracmil2_timevary = pcGOV_baseline/ pcGOV_nat
la var fracmil2_timevary "% of regional average per capita gov. spendings (time varying)"

*gen Bartik share (Predetermined)
gen fracmil2_lag = L.pcGOV / L.pcGOV_nat



/*
*gen Bartik share (Full Sample - levels)
local start = 1980
local end = 2014
bysort id: egen temp1 = mean(GOV_baseline) if Year <= `end' & Year >= `start'
bysort id: egen temp2 = mean(temp1) if Year >= `start' 
gen avrcapgovspend = temp2
	la var avrcapgovspend "average regional per capita gov. spendings"
bysort id: egen temp3 = mean(GOV_nat) if Year <= `end' & Year >= `start'
bysort id: egen temp4 = mean(temp3) if Year >= `start'
gen avrcapgovspend_nat = temp4
	la var avrcapgovspend_nat "average national per capita gov. spendings"
drop temp*
tsset id Year
gen fracmil = avrcapgovspend/avrcapgovspend_nat
	la var fracmil "% of regional average gov. spendings"

drop avrcapgovspend avrcapgovspend_nat
*/


********************************************************************************
* Preamble - Bartik Instrument Construction (IMF Alesina4 Alesina5 Alesina4_unpred Alesina4_fracmil2_lag)
********************************************************************************
merge m:1 Country Year using "$hp\Data\Out\Real\Data_IMFShocks.dta"
drop if cid == .
drop _merge

*interact with bartik share !

* baseline instrument!
gen Alesina4 = Alesina_4*fracmil2

* unpredicted component (Table C3 - row 1)
gen Alesina5 = Alesina_5*fracmil2

* lagged share  (Table C3 - row 6)
gen Alesina4_fracmil2_lag = Alesina_4*fracmil2_lag

* Guajardo + Klein IMF shock (Table C3 - row 7)
rename IMF IMFshock
gen IMF = IMFshock*fracmil2
label var IMF "IMF shock * fracmil2"
drop IMFshock

* Compute unpredicted version of the instrument (Table C3 - row 2)
xtset id Year
foreach var in pcGDP_nat Priv_Consumption_AMECOc CPI{
	cap gen l`var' = ln(`var')
	cap gen g`var' = l`var' - L.l`var'
	drop l`var'
}
foreach var in debtgdp  {
	cap gen g`var' = `var' - L.`var'
}
foreach var in IntRates_short IntRates_long {
	cap gen g`var' = `var'/100 - gCPI
}
reg Alesina_4 i.cid i.Year ///
L.gpcGDP_nat L.gPriv_Consumption_AMECOc L.debtgdp L.gIntRates_short  ///
L2.gpcGDP_nat L2.gPriv_Consumption_AMECOc L2.debtgdp L2.gIntRates_short  ///
if Nuts==0
predict resid if e(sample) == 1, resid
replace resid = 0 if Alesina_4 == 0 & Nuts ==0

egen Alesina_4_unpred = max(resid), by(cid Year)
gen Alesina4_unpred = Alesina_4_unpred*fracmil2

drop Alesina_*
drop fracmil2_*
drop Int*
drop debtgdp
drop gpcGDP_nat-resid



xtset id Year
order Country cid Nuts_id Name id Year

preserve
keep if Nuts == 0
save "${hp}Data\Out\Real\Data_Analysis_Nuts0.dta", replace
restore

preserve
keep if Nuts == 1 | Nuts == 2
save "${hp}Data\Out\Real\Data_Analysis_Nuts1.dta", replace
restore

keep if Nuts == 2

save "${hp}Data\Out\Real\Data_Analysis_Nuts2.dta", replace

preserve
* merge with Election Data
merge m:1 Nuts_id Year using "$hp\Data\Out\Elections\Data_Elections.dta"
drop _merge
xtset id Year
save "${hp}Data\Out\Data_Final_nuts2.dta", replace
restore

* merge with different Election Types
foreach election in National European Regional{
	preserve
	merge m:1 Nuts_id Year using "$hp\Data\Out\Elections\Data_`election'Elections.dta"
	drop _merge
	xtset id Year
	save "${hp}Data\Out\Data_Final_nuts2_`election'.dta", replace
	restore
}
