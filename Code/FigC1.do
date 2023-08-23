* Plotting Instrumment by Country 

use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

xtset id Year

* call instrument being used
local inst1 $inst

local varlist Far_Right Far_Left Valid
foreach var in `varlist'{
	replace `var' = `var'[_n-1] if `var' == . & Nuts_id == Nuts_id[_n-1]
}

drop if Valid==0 | Valid ==.
replace  `inst1' =  `inst1'*100

forvalues ciid = 1/8 {
preserve
keep if cid == `ciid'
collapse (sum) Far_Right Far_Left Valid (mean) HHI `inst1', by(Year Country)
keep if Year <= 2014
gen Far_Right_share	= Far_Right / Valid * 100

gen Far_Left_share	= Far_Left / Valid  * 100

gen Far_share		= Far_Left_share + Far_Right_share
sum Far_share
gen Mean_Far_share = r(mean)
sum HHI
gen Mean_HHI = r(mean)
gen zero=0

local country = Country

twoway (bar `inst1' Year, fcolor(gs13) lwidth(none) xlabel(1980(5)2015)) ///
(line zero Year, lcolor(black)), ///
ytitle("Austerity (% of GDP)") title(" `country' ") ylabel(-1(1)4) legend (off) scale(1.65)
graph export "$Fig\IMF_`country'.eps", replace
graph export "$Fig\IMF_`country'.pdf", replace


restore
}
