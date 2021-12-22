
* Open data
use DTA/final, clear
g transdata= inlist(trans,1)
gcollapse (max) transdata, by(stabb year) 
tempfile temp
save `temp', replace

* Open Data
use "DTA/Medicaid_FPL", clear
merge m:1 stname using "DTA\state_fips.dta", nogen
drop if year<2014

* Merge
merge m:1 stabb year using `temp', nogen

* Expansion status
g expansion = medicaid_FPL>=100 if !inlist(medicaid_FPL,.)

* Save years
sum year, meanonly
local years="`r(min)'-`r(max)'"

* Collapse into cross-sections
gcollapse (max) expansion transdata (count) transdata_yrs=transdata expansion_yrs=expansion, by(stabb)
replace expansion = 0 if inlist(expansion,.)
replace transdata = 0 if inlist(transdata,.)

* Set up
eststo clear

* Estimates
reg transdata expansion, r
eststo
estadd local years="`years'"
reg transdata expansion_yrs, r
eststo
estadd local years="`years'"
reg transdata_yrs expansion , r
eststo
estadd local years="`years'"
reg transdata_yrs expansion_yrs, r
eststo
estadd local years="`years'"

* Label Variables
label variable transdata "\shortstack{SOGI module\\status}"
label variable transdata_yrs "\shortstack{SOGI module\\years}"
label variable expansion "Medicaid expansion status"
label variable expansion_yrs "Medicaid expansion years"

* Save Table
esttab using "output/predicting_missing.tex" , replace nonotes se nomtitles alignment(x{2.2cm}) label stats(N years r2, label("Observations" "Years in sample" "\$R^2\$")) posthead(\midrule \textbf{Outcome:} & SOGI module status &SOGI module status&SOGI module years&SOGI module years \\\midrule) 

* Exit stata
exit, clear STATA