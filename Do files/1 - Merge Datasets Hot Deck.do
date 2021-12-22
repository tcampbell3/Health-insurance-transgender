
* Open BRFSS
use DTA/BRFSS_Pooled,clear

* Merge state names, drop obs outside of 50 states and DC
merge m:1 fips using DTA/state_fips, nogen keep(3)

**** Estimate FPL **** 

* Drop missing
foreach v in employ1 education marital race income2 {
	drop if `v'==9
}

*Append CPS
g brfss=1
g id=_n
append using "DTA/March CPS"
replace brfss=0 if brfss==.
replace id=0 if id==.

* Drop states not in BRFFS
glevelsof fips if inlist(brfss,1)
local states = r(levels)
local list=""
foreach state in `states'{
	local list="`list',`state'"
}
di "`list'"
keep if inlist(fips`list')

* Propensity score (see "Hot deck propensity score estimation for missing values")
logit brfss i.employ1 i.education age i.marital i.race year i.fips adults children income2
predict p 

* Find nearest 10 neighbors
save DTA/dummy, replace

* Find nearest 10 neighbors
clear
forvalues i=1/8{
	winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do files/1 - Merge Datasets Hot Deck - matchs.do" `i'
}

* Pause until finished
cap pause on 
qui di in red "Hot deck propensity score imputation runs on 8 cores, using 8 different statas. Must wait until each core has finished running. When finished type end into the command prompt and press enter"
pause:  type "end" into commands prompt to continue when all cores are finished

* Append core paritions
use DTA/matchs_1, clear
drop if id==.
forvalues i=2/8{
	append using DTA/matchs_`i'
	drop if id==.
}
save DTA/Matches, replace

* Merge fpl
use DTA/dummy, clear
drop if brfss==0
drop fpl
merge 1:1 id using DTA/Matches, assert(3) nogen

* Drop unused CPS variables
drop  marsupwt brfss p tax_id

* Poverty thresholds (alternative measure using only BRFSS info)
g hhpersons = adults+children
g inc = 5000 * inlist(income2,1) + 12500 * inlist(income2,2) + 17500 * inlist(income2,3) + 22500 * inlist(income2,4) + 30000 * inlist(income2,5) + 42500 * inlist(income2,6) + 62500 * inlist(income2,7) + 75000 * inlist(income2,8) if !inlist(income,77,99,.)
replace hhpersons = 9 if hhpersons > 9 & !inlist(hhpersons,.)
merge m:1  hhpersons children year using DTA/poverty_thresholds, nogen keep(1 3)
g fpl_brfss = inc/povertyline*100
drop hhpersons povertyline inc

* Save final dataset
save DTA/Final, replace	