
* Open Data
use "DTA/Medicaid_FPL", clear
merge m:1 stname using "DTA\state_fips.dta", nogen
drop if year<2014

* Indicate expansion states
g expansion_yrs = medicaid_FPL>=100 if !inlist(medicaid_FPL,.)
gcollapse (count) expansion_yrs, by(stabb)

* Create map
rename stabb state
maptile expansion_yrs, geo(state) cutvalues(0.5 1.5 2.5 3.5 4.5 5.5 6.5) twopt(legend(lab(1 "") lab(2 "Non-expansion") lab(3 "1 year") lab(4 "2 years") lab(5 "3 years") lab(6 "4 years") lab(7 "5 years") lab(8 "6 years") lab(9 "7 years")))

* Save Map
graph export Output/map_medicaid.pdf, replace 