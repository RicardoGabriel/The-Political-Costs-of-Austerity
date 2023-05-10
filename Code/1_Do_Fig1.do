				*** 1_Do_Fig1.do ***

set scheme s1color
graph set window fontface "Linux Biolinum O"        // set default font (window)
graph set window fontfacesans "Linux Biolinum O"    // set default sans font (window)
graph set window fontfaceserif "Linux Libertine O"  // set default serif font (window)
graph set window fontfacemono "DejaVu Sans Mono"    // set default mono font (window)

*Choose Nuts level to perform the analysis on
global nu = 2
local inst1 Alesina_4
local instrument "Alesina"
global inst1 Alesina_4

* Upload data
use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

local Italy = "$noItaly"
if "`Italy'" == "_noItaly"{
	drop if cid == 5
}

xtset id Year
sort id Year

local varlist Far_Right Far_Left Valid
foreach var in `varlist'{
	replace `var' = `var'[_n-1] if `var' == . & Nuts_id == Nuts_id[_n-1]
}

drop if Valid==0 | Valid ==.

collapse (sum) Far_Right Far_Left Valid `inst1', by(Year)
keep if Year <= 2015
gen Far_Right_share	= Far_Right / Valid * 100
sum Far_Right_share 
gen Mean_Far_Right_share = r(mean)
gen Far_Left_share	= Far_Left / Valid  * 100
sum Far_Left_share
gen Mean_Far_Left_share = r(mean)
gen Far_share		= Far_Left_share + Far_Right_share
sum Far_share
gen Mean_Far_share = r(mean)

gen zero=0

_pctile  `inst1', p(70)
gen Event1				= 25 if  `inst1' >= r(r1)
gen Event2				= 25 if  `inst1' >= 0


* Graph Total Share
twoway (bar Event1 Year, fcolor(gs12) lwidth(none) xlabel(1980(5)2015)) ///
(line Far_share Year, ylabel(0(5)25) lcolor(black) lwidth(medthick)) ///
(line Mean_Far_share Year, lcolor(black) lpattern("-")) ///
(rarea zero Far_Right_share Year, color(red%40)) ///
(rarea Far_Right_share Far_share Year, color(blue%40)), ///
legend(order(4 "Vote share far right, %" ///
3 "Average vote share far parties, %" 5 "Vote share far left, %" ///
1 "Episodes of extreme austerity") cols(2))
graph export "$Fig\Fig1`Italy'.pdf", replace


********************************************************************************
** 					Plotting Instrumment by Country 
********************************************************************************
* Upload data
use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

xtset id Year
sort id Year

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
graph export "$Fig\IMF_`country'.pdf", replace


restore
}
