* Stocastic Regression Imputation
set seed 19361938
use DTA/BRFSS_Pooled,clear
g brfss=1
append using "DTA/March CPS"
replace brfss=0 if brfss==.
replace children = 5 if children>5
replace adults = 5 if adults>5
g hhsize=children+adults
g hhtop=hhsize==10
forvalues i = 1/8{
	qui reg fpl i.employ1 i.education age i.marital i.race c.hhsize i.hhtop i.year i.fips [aw=marsupwt] ///
		if income2==`i'
	g _e = rnormal(0,e(rmse))
	predict _p
	replace fpl = _p+_e if income2 == `i' & income2==`i'
	drop _e _p
}
drop if brfss==0
g double wt=_llcpwt
g hist=1
keep fpl wt hist

* CPS FPL
append using "DTA/March CPS"
replace wt=marsupwt if wt==.
replace hist=2 if hist==.
keep fpl wt hist

* Hot Deck Propensity Score Imputation
append using "DTA/Final"
replace wt=_llcpwt if wt==.
replace hist=3 if hist==.
keep fpl wt hist

* Adjust weights
egen total=total(wt),by(hist)
g weight=round(wt/total*10000000000000)
sum weight
assert r(min)!=0	// must scale high enough so no observation is dropped


* Regression Imputation vs CPS
twoway	(hist fpl [fw=weight] if hist==1 ,color(blue%40))	///
		(hist fpl [fw=weight] if hist==2 ,color(red%40))	///
		, scheme(plotplain) xtitle("Federal Poverty Level",size(11pt)) xlabel(-3000(3000)18000) ///
		ytitle("Density",size(11pt)) ///
		legend(order(2 "March Current Population Survey" 1 "Stochatic Regression Imputation") size(10pt) row(1) pos(6))	
graph export "Output/regression_impute.pdf", replace	
		
* HDPS Imputation vs CPS
twoway	(hist fpl [fw=weight] if hist==3 ,color(blue%40))	///
		(hist fpl [fw=weight] if hist==2 ,color(red%40))	///
		, scheme(plotplain) xtitle("Federal Poverty Level",size(11pt)) xlabel(0(3000)18000) ///
		ytitle("Density",size(11pt)) ///
		legend(order(2 "March Current Population Survey" 1 "Hot Deck Propensity Score Imputation") size(10pt) row(1) pos(6))
graph export "Output/hdps_impute.pdf", replace			