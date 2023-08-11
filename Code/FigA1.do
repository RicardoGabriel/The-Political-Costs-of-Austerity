				*** A3_NUTS_Variation ***


*Choose main instrument
local inst $inst

set scheme s1color
graph set window fontface "Linux Biolinum O"        // set default font (window)
graph set window fontfacesans "Linux Biolinum O"    // set default sans font (window)
graph set window fontfaceserif "Linux Libertine O"  // set default serif font (window)
graph set window fontfacemono "DejaVu Sans Mono"    // set default mono font (window)
eststo clear





********************************************************************************
* Reporting within-NUTS1 variation in NUTS2 values

* Share of NUTS2-NUTS1 distribution in the instrument

* One can do the same exercise for Nuts0 easily and for other variables such as far vote share, and gov. spending
********************************************************************************

use "${hp}Data\Out\Real\Data_Analysis_Nuts1.dta", clear

* for exposure purposes scale the instrument
replace Alesina4 = Alesina4*(-100)

* for the purpose of the exercise exclude regions where NUTS1=NUTS2
drop if Nuts_id=="PT3" | Nuts_id=="PT2" | Nuts_id=="PT30" | Nuts_id=="PT20" | Nuts_id=="DE60" | Nuts_id=="DE6" | Nuts_id=="DE80" | Nuts_id=="DE8" | Nuts_id=="DE30" | Nuts_id=="DE3" | Nuts_id=="DE40" | Nuts_id=="DE4" | Nuts_id=="DE50" | Nuts_id=="DE5" | Nuts_id=="DEC0" | Nuts_id=="DEC" | Nuts_id=="DEE0" | Nuts_id=="DEE" | Nuts_id=="DEF0" | Nuts_id=="DEF" | Nuts_id=="DEG0" | Nuts_id=="DEG" | Nuts_id=="ES30" | Nuts_id=="ES3" | Nuts_id=="ES70" | Nuts_id=="ES7" | Nuts_id=="FR10" | Nuts_id=="FR1" | Nuts_id=="FRB0" | Nuts_id=="FRB" | Nuts_id=="FRG0" | Nuts_id=="FRG" | Nuts_id=="FRH0" | Nuts_id=="FRH" | Nuts_id=="FRL0" | Nuts_id=="FRL" | Nuts_id=="FRM0" | Nuts_id=="FRM"

* Mathias approach: look at sumary statistics for the instrument at Nuts 1 and Nuts 2
sum Alesina4 if Nuts==1 & Alesina4!=0, d
hist Alesina4 if Nuts==1 & Alesina4!=0

sum Alesina4 if Nuts==2 & Alesina4!=0, d
hist Alesina4 if Nuts==2 & Alesina4!=0

*create NUTS1 code for Nuts2
gen Nuts1_id = substr(Nuts_id,1,3) if Nuts==2
replace Nuts1_id=Nuts_id if Nuts==1

* repeat variables of interest to a column with Nuts1 values for each Nuts2
gen Alesina4_Nuts1 = Alesina4 if Nuts==1

* trick to get values given time dimension is the same for every region
replace Alesina4_Nuts1 = Alesina4_Nuts1[_n-38] if Alesina4_Nuts1==.

* draw distributions only for years where fiscal consolidations occur (or are reversed)
drop if Nuts==1
gen Alesina4_dif = (Alesina4 - Alesina4_Nuts1)

sum Alesina4_dif if Alesina4!=0, d
hist Alesina4_dif if Alesina4!=0, width(0.02)


replace Alesina4_dif = abs(Alesina4_dif)
*drop if Alesina4_dif == .
*drop if Alesina4_dif[_n+1]==Alesina4_dif[_n]
*drop if Nuts_id[_n+1]==Nuts_id[_n]
hist Alesina4_dif if Alesina4!=0, width(0.02) xtitle("Instrument") scale(2)
graph export "$Fig\FigA1a.eps", replace
reg Alesina4_dif if Alesina4 !=0
outreg2 using $Tab\TableA6.xls, tstat bracket e(N_full) label excel bdec(2) replace




********************************************************************************
* 
********************************************************************************


use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

sort id Year

*to have the same sample when looking at real and political variables
drop if Far_share==.

********************************************************************************
*Step 1)					DATA PREPARATION
********************************************************************************
	
foreach var in Far_share {
	forvalues i=0/1 {
		qui gen F`i'`var' = 100*(F`i'.`var' - L.`var')
		label var F`i'`var' "Forward `i' year change in `var', pp"
	}
} 

*forward changes for control variables
foreach lhsvar in pcGDP Population EmpAbs pwHours pwComp pcVehicles pcInv HHI LaborShare pcGOV{	
	forvalues i = 0/1 {	
		gen F`i'`lhsvar' = (F`i'.`lhsvar' - L.`lhsvar') / L.`lhsvar' *100
		label var F`i'`lhsvar' "Forward `i' year change in `lhsvar', percent %"		
	}
}

*forward change of RHS variable in growth rates (%)
foreach lhsvar in pcGOV {
	forvalues i = 0/1 {
		gen F`i'`lhsvar'RHS = (F`i'.`lhsvar' - L.`lhsvar') / L.pcGOV * (100)    // *(-1) because we want to analyze the impact of austerity: a drop in gov spending!
	}
}




********************************************************************************
* Reporting within-NUTS1 variation in NUTS2 values

* Share of NUTS2-NUTS1 distribution in the regional vote shares
********************************************************************************
preserve
* for the purpose of the exercise exclude regions where NUTS1=NUTS2
drop if Nuts_id=="PT30" | Nuts_id=="PT20" | Nuts_id=="DE60" | Nuts_id=="DE6" | Nuts_id=="DE80" | Nuts_id=="DE8" | Nuts_id=="DE30" | Nuts_id=="DE3" | Nuts_id=="DE40" | Nuts_id=="DE4" | Nuts_id=="DE50" | Nuts_id=="DE5" | Nuts_id=="DEC0" | Nuts_id=="DEC" | Nuts_id=="DEE0" | Nuts_id=="DEE" | Nuts_id=="DEF0" | Nuts_id=="DEF" | Nuts_id=="DEG0" | Nuts_id=="DEG" | Nuts_id=="ES30" | Nuts_id=="ES3" | Nuts_id=="ES70" | Nuts_id=="ES7" | Nuts_id=="FR10" | Nuts_id=="FR1" | Nuts_id=="FRB0" | Nuts_id=="FRB" | Nuts_id=="FRG0" | Nuts_id=="FRG" | Nuts_id=="FRH0" | Nuts_id=="FRH" | Nuts_id=="FRL0" | Nuts_id=="FRL" | Nuts_id=="FRM0" | Nuts_id=="FRM"


*create NUTS1 code for Nuts2
gen Nuts1_id = substr(Nuts_id,1,3) if Nuts==2

* repeat variables of interest to a column with Nuts1 values for each Nuts2
gen Far = Far_Left + Far_Right
bys Nuts1_id Year: egen Far_Nuts1 = total(Far)
bys Nuts1_id Year: egen Votes_Nuts1 = total(Valid)
gen Far_share_Nuts1 = Far_Nuts1 / Votes_Nuts1

xtset id Year
gen F0Far_share_Nuts1 = 100*(F0.Far_share_Nuts1 - L.Far_share_Nuts1)


* draw distributions (only for election years)
gen F0Far_share_dif = (F0Far_share - F0Far_share_Nuts1)
replace F0Far_share_dif = . if ElectionType == .

sum F0Far_share_dif, d
hist F0Far_share_dif


replace F0Far_share_dif = abs(F0Far_share_dif)
hist F0Far_share_dif, width(0.5) xtitle("Far vote share (p.p.)") scale(2)
graph export "$Fig\FigA1b.eps", replace
reg F0Far_share_dif
outreg2 using $Tab/TableA6.xls, tstat bracket e(N_full) label excel bdec(2)

restore


********************************************************************************
* Reporting within-NUTS1 variation in NUTS2 values

* Share of NUTS2-NUTS1 distribution in the government spending variable
********************************************************************************
preserve
* for the purpose of the exercise exclude regions where NUTS1=NUTS2
drop if Nuts_id=="PT30" | Nuts_id=="PT20" | Nuts_id=="DE60" | Nuts_id=="DE6" | Nuts_id=="DE80" | Nuts_id=="DE8" | Nuts_id=="DE30" | Nuts_id=="DE3" | Nuts_id=="DE40" | Nuts_id=="DE4" | Nuts_id=="DE50" | Nuts_id=="DE5" | Nuts_id=="DEC0" | Nuts_id=="DEC" | Nuts_id=="DEE0" | Nuts_id=="DEE" | Nuts_id=="DEF0" | Nuts_id=="DEF" | Nuts_id=="DEG0" | Nuts_id=="DEG" | Nuts_id=="ES30" | Nuts_id=="ES3" | Nuts_id=="ES70" | Nuts_id=="ES7" | Nuts_id=="FR10" | Nuts_id=="FR1" | Nuts_id=="FRB0" | Nuts_id=="FRB" | Nuts_id=="FRG0" | Nuts_id=="FRG" | Nuts_id=="FRH0" | Nuts_id=="FRH" | Nuts_id=="FRL0" | Nuts_id=="FRL" | Nuts_id=="FRM0" | Nuts_id=="FRM"


*create NUTS1 code for Nuts2
gen Nuts1_id = substr(Nuts_id,1,3) if Nuts==2

* repeat variables of interest to a column with Nuts1 values for each Nuts2
bys Nuts1_id Year: egen GOV_Nuts1 = total(GOV)
bys Nuts1_id Year: egen Population_Nuts1 = total(Population)
gen pcGOV_Nuts1 = GOV_Nuts1 / Population_Nuts1

xtset id Year
gen F0pcGOV_Nuts1 = (F0.pcGOV_Nuts1 - L.pcGOV_Nuts1) / L.pcGOV_Nuts1


* draw distributions
gen F0pcGOV_dif = (F0pcGOVRHS - F0pcGOV_Nuts1)
*replace F0pcGOV_dif = . if ElectionType == .

sum F0pcGOV_dif, d
hist F0pcGOV_dif

replace F0pcGOV_dif = abs(F0pcGOV_dif)
hist F0pcGOV_dif, width(1) xtitle("Gov. spending growth (%)") scale(2)
graph export "$Fig\FigA1c.eps", replace
reg F0pcGOV_dif
outreg2 using $Tab/TableA6.xls, tstat bracket e(N_full) label excel bdec(2)

restore
