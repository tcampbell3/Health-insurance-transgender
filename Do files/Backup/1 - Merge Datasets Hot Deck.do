
* Open BRFSS
use DTA/BRFSS_Pooled,clear

* Merge state names, drop obs outside of 50 states and DC
merge m:1 fips using DTA/state_fips, nogen keep(3)

* Medicaid thresholds
merge m:1 stname year using DTA/Medicaid_FPL, nogen keep(1 3) 
	
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

* Medicaid running variable
g medicaid_run = fpl - medicaid_FPL

	
**** Merge ACA Subsidy Schedule **** 

* generate FPL group to match on
g fpl_group = 1 if fpl < 133
replace fpl_group = 2 if fpl >= 133 & fpl < 150
replace fpl_group = 3 if fpl >= 150 & fpl < 200
replace fpl_group = 4 if fpl >= 200 & fpl < 250
replace fpl_group = 5 if fpl >= 250 & fpl < 300
replace fpl_group = 6 if fpl >= 300 & fpl < 400
replace fpl_group = . if fpl==.

* Merge
merge m:1 year fpl_group using  DTA/ACA_Subsidy_Schedule, keep(1 3) nogen

* Define ACA Subsidy on linear slide scale
g cap = ((final-initial)/(upper-lower)) * (fpl - lower) + initial 
replace cap = 100 if fpl<100 | fpl>=400
replace cap = . if fpl==.
drop fpl_group description initial final lower upper

* Save final dataset
g X=.
save DTA/Final, replace	