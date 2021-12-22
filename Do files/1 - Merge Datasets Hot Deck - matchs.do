* Create FPL frame to store imputed values
cap frame change default
cap frame drop fpl
frame create fpl id fpl

* Sample in this core
global core = `1'
use DTA/dummy,clear
sum id
local max=r(max)
global first=round(`max' / 8 * (${core}-1)) + 1
global last=round(`max' / 8 * (${core}))
keep if id==0 | id>=$first & id<=$last
g _index = _n

* Find first and last observations that need imputation
sum _index if !inlist(id,0),meanonly
local first_missing=r(min)				// Last observation of missing data
local last_missing=r(max)				// Last observation of missing data

* Find first and last observations that are potential matches
sum _index if inlist(id,0),meanonly
local first_cps = r(min)				// Defines the number neightbors, k, used to determine imputation statistic
local last_cps = r(max)					// Last line of data

* test for errors
assert `first_missing' == 1				
assert `first_cps' == `last_missing'+1

* Find nearest 10 neighbors, loop over all observations in core
timer clear
set seed 19361938
tempname neighbors
forvalues i = `first_missing' / `last_missing' {
	
	timer on 1
	quietly{
	
	* local observation ID
	local id: di id[`i'] 
	
	* Save propensity score of observation being imputed
	local pscore: di p[`i'] 
	
	* Save difference (0 is perfect match)
	cap drop _diff
	g _diff = abs(p-`pscore') in `first_cps'/`last_cps'	

	* Create frame with only closest .01% of nonmissing dataset (speeds up run time substantially)
	gquantiles _diff, _pctile percentiles(.1)								// requires gtools package
	cap frame drop `neighbors'
	frame put in `first_cps'/`last_cps' if _diff <= r(r1), into(`neighbors')
	
	* Randomly choose  one of 10 closest neighbors
	frame `neighbors'{
		g random_choice1=rnormal() 
		gsort _diff random_choice1
		g random_choice2=rnormal() in 1/10
		gsort random_choice2
		local fpl = fpl[1]
	}

	* Store imputed value 
	frame post fpl (`id') (`fpl')
	
	}
	timer off 1
	timer list 1
}
frame change fpl
save DTA/matchs_${core}, replace

* Exit stata
exit, clear STATA