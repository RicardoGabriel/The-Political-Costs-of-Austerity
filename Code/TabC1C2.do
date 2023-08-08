* Relationship between the instrument and lagged economic and political variables
* Relationship between the instrument and extreme parties vote share


*Choose main instrument (IMF or Alesina1-4)
local inst $inst

set scheme s1color
graph set window fontface "Linux Biolinum O"        // set default font (window)
graph set window fontfacesans "Linux Biolinum O"    // set default sans font (window)
graph set window fontfaceserif "Linux Libertine O"  // set default serif font (window)
graph set window fontfacemono "DejaVu Sans Mono"    // set default mono font (window)
eststo clear






use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear
merge m:1 Nuts_id using "${hp}Data\Eurostat\Area.dta"

sort id Year

*to have the same sample when looking at real and political variables
drop if Far_share==.

********************************************************************************
*Step 1)					DATA PREPARATION
********************************************************************************

gen density = Population /Area * 100

	
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
* Predicting the instrument - Table C1
********************************************************************************

replace `inst' = `inst'*(-100)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs l.F0pwComp l.F0HHI l.F0pwHours l.F0LaborShare l.F0pcGOV l.`inst', absorb(Year id)  cluster(id Year)
outreg2 using "$Tab\TableC1.xls", tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y) replace


********************************************************************************
* Predicting the share with the mean extreme vote share change - Table C2
********************************************************************************

drop if F0Far_share == 0
bys id: egen average = mean(F0Far_share)

drop if average[_n+1]==average[_n]
sum average,d

plot average fracmil2

reg average fracmil2

reghdfe fracmil2 average, noabsorb
outreg2 using "$Tab\TableC2.xls", tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, N, Region FE, N, Cluster Region, N, Cluster Year, N) replace
