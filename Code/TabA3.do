* Correlation Between Government Spending and our proxy by Country

use "${hp}Data\Out\Real\Data_Analysis_Nuts0.dta", clear

* Use same sample as main analysis
keep if inrange(Year,1980,2015)


* Adjusted non-market GVA with intermediate consumption at NUTS 0 - GOV_nat
drop GOV
rename GOV_nat GOV
gen ln_GOV = ln(GOV)

* AMECO government spending series
gen GOV_AMECO 	= Gov_Spending_AMECO * GDP_nat / 100
gen ln_GOV_AMECO= ln(GOV_AMECO)

* by countries

levelsof Country, local(clist)
foreach c in `clist' {
	corr GOV GOV_AMECO if Country == "`c'"
	global c3: di %6.3fc r(rho)
	
	corr ln_GOV ln_GOV_AMECO if Country == "`c'"
	global c4: di %6.3fc r(rho)
	
	corr GOV GOV_AMECO if Country == "`c'" & inrange(Year,1995,2015)
	global c1: di %6.3fc r(rho)
	
	corr ln_GOV ln_GOV_AMECO if Country == "`c'" & inrange(Year,1995,2015)
	global c2: di %6.3fc r(rho)
	
	if "`c'" == "Austria"{
		texdoc init "$Tab\TableA3.tex", replace force
		tex `c' & ${c1} & ${c2} & & ${c3} & ${c4}   \\
		texdoc close

	}
	else{
		texdoc init "$Tab\TableA3.tex", append force
		tex `c' & ${c1} & ${c2} & & ${c3} & ${c4}   \\
		texdoc close
	}
}

* all countries
corr GOV GOV_AMECO 
global c3: di %6.3fc r(rho)

corr ln_GOV ln_GOV_AMECO 
global c4: di %6.3fc r(rho)

corr GOV GOV_AMECO if inrange(Year,1995,2015)
global c1: di %6.3fc r(rho)

corr ln_GOV ln_GOV_AMECO if inrange(Year,1995,2015)
global c2: di %6.3fc r(rho)

texdoc init "$Tab\TableA3.tex", append force
tex \midrule \addlinespace
tex All & ${c1} & ${c2} & & ${c3} & ${c4}  \\ \addlinespace \bottomrule \addlinespace
texdoc close
		
