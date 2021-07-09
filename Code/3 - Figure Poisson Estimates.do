* Set up log file
cd "${path}"
cap log close 
log using "Output/session_${kernel}", replace

* Programs
do "Do Files/3 - RDD Programs"

* Open Data and Create variables to fill with estimates
use DTA/Final, clear
g est=.
g y =. 
g x =.
g outcome=""
g gender=.

* Loop Estimates for 30 day variables
local i=1
local j=1
foreach outcome in poor physical mental{
foreach g in cis trans {
	
	* Stacked 2SLS
	preserve
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	if lower("${age}")=="yes"{
		keep if inlist(rd,1,2)
	}
	drop if insurance==. | `outcome' ==.
	sum insurance [aw=_weight],meanonly
	local pre=r(mean)
	cap drop _res
	qui reghdfe insurance c.run#rd c.rT#rd c.T#rd c.(_x*)#i.rd [aw=_weight], cluster(_psu) a(fips#rd#year) res
	predict _res,res
	qui ppmlhdfe `outcome' insurance _res c.run#rd c.rT#rd c.(_x*)#i.rd [pw=_weight], vce(cluster _psu) d a(fips#rd#year)
	margins [aw=_weight], at((asobserved)) at(insurance=generate(insurance +(1-`pre'))) contrast(at(r._at)) noestimcheck
	margins [aw=_weight], dydx(insurance) at((asobserved)) post noestimcheck
	lincom insurance *(1-`pre')
	local est=r(estimate)
	local ub=r(ub)
	local lb=r(lb)
	restore

	replace est=`est' in `i'
	replace x=`lb' in `i'
	replace outcome="`outcome'" in `i'
	replace gender=`g' in `i'	
	replace y=`j' in `i'
	local i=`i'+1
	
	replace est=`est' in `i'
	replace x=`ub' in `i'
	replace outcome="`outcome'" in `i'
	replace gender=`g' in `i'
	replace y=`j' in `i'
	local i=`i'+1
	local j=`j'+1
	
}
local j=`j'+1	// add space between var
}

* Graph (index is y axis)
twoway (line y x if y==1,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==2,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==4,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==5,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==7,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==8,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(scatter y est if gender==1,  mfc("85 205 252") mlc(black*.7) ms(D) msiz(medlarge)) ///
(scatter y est if gender==0,  mfc("247 168 184") mlc(black*.7) ms(D) msiz(medlarge)) ///
, ymlabel(1.7 "Bad health" 1.3 "days     " 4.7 "Bad physical" 4.3 "health days " 7.7 "Bad mental" 7.3 "health days", labsize(medsmall) notick) ///
ylabel(0 " " 3 " " 6 " " 9 " ") ///
legend( row(1) order(2 "Transgender" 1 "Cisgender") pos(6)) 							///
scheme(plotplain) ytitle("") xline(0, lcolor(grey*.6) lp(dash)) xtitle("") ysize(10)

* Save
graph export "Output/Poisson_30_day_${kernel}_${age}.pdf", replace		

* Graph with large font for presentation
twoway (line y x if y==1,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==2,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==4,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==5,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==7,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==8,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(scatter y est if gender==1,  mfc("85 205 252") mlc(black*.7) ms(D) msiz(medlarge)) ///
(scatter y est if gender==0,  mfc("247 168 184") mlc(black*.7) ms(D) msiz(medlarge)) ///
, ymlabel(1.7 "Bad health" 1.3 "days     " 4.7 "Bad physical" 4.3 "health days " 7.7 "Bad mental" 7.3 "health days", labsize(huge) notick) ///
ylabel(0 " " 3 " " 6 " " 9 " ") xlab(, labsize(huge)) ///
legend( row(1) order(2 "Trans" 1 "Cis") pos(6) size(*3) symx(*2))  	///
scheme(plotplain) ytitle("") xline(0, lcolor(grey*.6) lp(dash)) xtitle("") ysize(10)

* Save
graph export "Output/Poisson_30_day_${kernel}_${age}_bigfont.pdf", replace	




* Save log file
translate "Output/session_${kernel}.smcl" "Output/session_${kernel}_${age}.pdf", replace
log close 