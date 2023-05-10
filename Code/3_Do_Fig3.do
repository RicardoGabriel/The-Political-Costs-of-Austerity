 					*** 3_Do_Fig3 ***
 

*Choose Nuts level to perform the analysis on
global nu = 2
local inst "$inst"
local instrument "Alesina"
local inst = "$inst"

local inst1 Alesina_4
local instrument "Alesina"
global inst1 Alesina_4

* Upload data
use "${hp}Data\Out\Data_Final_nuts${nu}_National.dta", clear
use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

local Italy = "$noItaly"
if "`Italy'" == "_noItaly"{
	drop if cid == 5
}

keep if ElectionType == 1
xtset id Year
sort id Year

local lhsvarlist Far_Left_share Far_Right_share Far_share 
foreach var in `lhsvarlist'{
	gen d`var' 		= 100*(`var' - `var'[_n-1]) if Nuts_id==Nuts_id[_n-1]
}

foreach var in pcGOV{
	gen d`var' 		= (`var' -`var'[_n-1])/ `var'[_n-1] *100 if Nuts_id==Nuts_id[_n-1]
}

* Scatter Plot
twoway (scatter dFar_share dpcGOV if inrange(Year,1980,2015) ) ///
(lfit dFar_share dpcGOV if inrange(Year,1980,2015)), ///
xtitle("Change pc government spending (%)") ytitle("Change extreme parties vote share (pp)") legend(off)
graph export "$Fig\Fig3`Italy'.pdf", replace

pwcorr dFar_share dpcGOV if inrange(Year,1980,2015) , star(0.01) /*  -0.3917* */

set scheme s2color
