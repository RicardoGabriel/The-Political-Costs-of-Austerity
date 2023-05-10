				*** 17_Revision ***


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
* Predicting the instrument
********************************************************************************

cd $Tab

replace `inst' = `inst'*(-100)



********************************************************************************
* With current information (t-1 to t)
********************************************************************************

/*
reghdfe `inst', noabsorb
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, N, Region FE, N, Cluster Region, N, Cluster Year, N) replace

reghdfe `inst', noabsorb  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, N, Region FE, N, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst', absorb(Year)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, N, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst', absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share F0Population, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share F0Population F0EmpAbs, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share F0Population F0EmpAbs, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share F0Population F0EmpAbs F0pwComp, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share F0Population F0EmpAbs F0pwComp, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share F0Population F0EmpAbs F0pwComp F0pcInv, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share F0Population F0EmpAbs F0pwComp F0pcInv F0HHI, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst'  F0pcGDP F0Far_share F0Population F0EmpAbs F0pwComp F0pcInv F0HHI F0pwHours F0LaborShare, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision1`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)
*/

********************************************************************************
* With lagged information (t-2 to t-1)
********************************************************************************


reghdfe `inst', noabsorb
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, N, Region FE, N, Cluster Region, N, Cluster Year, N) replace

reghdfe `inst', noabsorb  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, N, Region FE, N, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst', absorb(Year)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, N, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst', absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs l.F0pwComp, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs l.F0pwComp, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

*reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs l.F0pwComp l.pcInv, absorb(Year id)  cluster(id Year)
*outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs l.F0pwComp l.F0HHI, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs l.F0pwComp l.F0HHI l.F0pwHours l.F0LaborShare, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs l.F0pwComp l.F0HHI l.F0pwHours l.F0LaborShare l.F0pcGOV, absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)

reghdfe `inst' l.F0pcGDP l.F0Far_share l.F0Population l.F0EmpAbs l.F0pwComp l.F0HHI l.F0pwHours l.F0LaborShare l.F0pcGOV l.`inst', absorb(Year id)  cluster(id Year)
outreg2 using Table_Revision2`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, Y, Region FE, Y, Cluster Region, Y, Cluster Year, Y)


********************************************************************************
* predicting the share with the mean extreme vote share change
********************************************************************************

preserve
drop if F0Far_share == 0
bys id: egen average = mean(F0Far_share)

drop if average[_n+1]==average[_n]
sum average,d

plot average fracmil2

reg average fracmil2

reghdfe fracmil2 average, noabsorb
outreg2 using Table_Revision3`Italy'.xls, tstat bracket e(N_full) label excel bdec(2) addtext(Year FE, N, Region FE, N, Cluster Region, N, Cluster Year, N) replace

restore








********************************************************************************
* Counting number of consolidations - page 
********************************************************************************

* keep country data
duplicates drop Year cid, force

bys core: sum Alesina_4 if Alesina_4>0



********************************************************************************
* Graveyard
********************************************************************************


/*
*  compare the standard deviation of Nuts 1 to each Nuts 2 regions
bys id: egen sd_A4_N2 = sd(Alesina4)
bys id: egen sd_A4_N1 = sd(Alesina4_Nuts1)
gen sd_dif = sd_A4_N2 - sd_A4_N1
drop if sd_dif[_n+1]==sd_dif[_n]
sum sd_dif, d
reg sd_dif
*/


********************************************************************************
* Instrument's descriptives statistics
********************************************************************************

cd $Tab

replace Alesina4 = Alesina4*100

* obtain summary statistics by type of country
eststo clear
 
estpost sum Alesina4
est store a 
estpost sum Alesina4 if core==1
est store b
estpost sum Alesina4 if core==0
est store c


 
esttab a b c using SumStat.tex, replace ///
mtitles("\textbf{\emph{Full}}" "\textbf{\emph{North}}" "\textbf{\emph{South}}") ///
collabels(\multicolumn{1}{c}{{Mean}} \multicolumn{1}{c}{{Std.Dev.}} \multicolumn{1}{l}{{Obs}}) ///
cells("mean(fmt(2)) sd(fmt(2)) count(fmt(0))") label nonumber f noobs alignment(S) booktabs



gen Alesina4_0 = Alesina4 if Alesina4!=0 & Alesina4!=.


estpost tabstat Alesina4 Alesina4_0 Far_share F0pcGOV, by() stat(n mean sd min max) col(stat)
esttab using "$Tab\Table_Descriptives.tex", cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") noobs nonumber label replace ///
	title("Descriptive statistics \label{T:Descriptives}")
