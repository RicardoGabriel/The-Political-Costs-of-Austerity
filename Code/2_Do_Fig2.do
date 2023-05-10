				*** 2_Do_Fig2.do ***

********************************************************************************
*** Map with far vote share
********************************************************************************
use "${hp}Data\Out\Data_Final_nuts${nu}.dta", clear
preserve
merge m:m Nuts_id using "${hp}Code\DataPrep\eucoord"
drop _merge

replace Far_share = Far_share * 100
drop if Nuts_id == "FRY1" | Nuts_id == "FRY2" | Nuts_id == "FRY3" | ///
Nuts_id == "FRY4" | Nuts_id == "FRY5" | Nuts_id == "FR" | Nuts_id == "TR" ///
| Nuts_id=="CY" 

local Italy = "$noItaly"
if "`Italy'" == "_noItaly"{
	drop if cid == 5
}

*Fig 2a
local year = 2007 
spmap Far_share using "${hp}Code\DataPrep\eucoord_shp" ///
if Nuts_id!="ES63" & Nuts_id!="ES64" & Nuts_id!="PT20" & Nuts_id!="PT30" & Nuts_id!="FI20" & Year == `year' , ///
id(_ID) fcolor(Oranges) clm(c) clb(0 05 10 15 20 30 40 70) legend(size(medium) position(10)) 
graph export "$Fig\Fig2a`Italy'.png", replace	
graph export "$Fig\Fig2a`Italy'.pdf", replace	

*Fig 2b
local year = 2015 
spmap Far_share using "${hp}Code\DataPrep\eucoord_shp" ///
if Nuts_id!="ES63" & Nuts_id!="ES64" & Nuts_id!="PT20" & Nuts_id!="PT30" & Nuts_id!="FI20" & Year == `year' , ///
id(_ID) fcolor(Oranges) clm(c) clb(0 05 10 15 20 30 40 70) legend(size(medium) position(10)) 
graph export "$Fig\Fig2b`Italy'.png", replace	
graph export "$Fig\Fig2b`Italy'.pdf", replace	
