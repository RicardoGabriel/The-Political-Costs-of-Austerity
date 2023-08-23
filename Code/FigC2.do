* Map with European Regions and share si

use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear

***When you run it the first time:
** Install necessary commmands
*ssc install spmap
*ssc install shp2dta
*ssc install mif2dta

preserve
merge m:m Nuts_id using "${hp}Code\eucoord"
drop _merge

keep if Year ==2014 | Year == .
drop if LEVL_CODE > 0 & Year == .
drop if Nuts_id == "FRY1" | Nuts_id == "FRY2" | Nuts_id == "FRY3" | ///
Nuts_id == "FRY4" | Nuts_id == "FRY5" | Nuts_id == "FR" | Nuts_id == "TR" ///
| Nuts_id=="CY" | Nuts_id == "ES63" | Nuts_id == "ES64" | Nuts_id == "PT20" ///
| Nuts_id == "PT30" | Nuts_id == "FI20" 


sum fracmil2, d
scalar m = r(min)
spmap fracmil2 using "${hp}Code\eucoord_shp" if Nuts_id != "PT", ///
id(_ID) fcolor(Blues2) clm(c) clb(0.72 0.86 0.92 1.03 1.57) legend(size(medium) position(10)) 
 
graph export "$Descriptives\FigC2.eps", replace	
graph export "$Descriptives\FigC2.pdf", replace	
