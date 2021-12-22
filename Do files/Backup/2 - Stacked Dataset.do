set seed 19361938
mata: rseed(19361938)

* Program kernel weights
cap program drop kernel_weight
program kernel_weight

	syntax [, kernel(string) left(real 1.0) right(real 1.0)]
	cap drop _weight
	assert "`kernel'"=="tri" |  "`kernel'"=="uni" |  "`kernel'"=="epa"
	
	* Triangular kernel - see calonico (2014) page 912
	if "`kernel'"=="tri"{
	
		* Left
		g _weight = max( 0 , 1-abs(run/`left') ) / `left' * _llcpwt if run<0
		
		* Right, including zero
		replace _weight = max( 0 , 1-abs(run/`right') ) / `right' * _llcpwt if run>=0
		
	}
	
	* Uniform kernel - see calonico (2014) page 912
	if "`kernel'"=="uni"{
	
		* Left
		g _weight = max( 0 , 1/2) / `left' * _llcpwt if run<0
		
		* Right, including zero
		replace _weight = max( 0 , 1/2) / `right' * _llcpwt if run>=0
		
	}
	
	* Normal kernel - see calonico (2014) page 912
	if "`kernel'"=="epa"{
	
		* Left
		g _weight = max( 0 , 3/4 * (1 - (run/`left')^2)) / `left' * _llcpwt if run<0
		
		* Right, including zero
		replace _weight = max( 0 , 3/4 * (1 - (run/`right')^2)) / `right' * _llcpwt if run>=0
		
	}	
	end


* 1) Select potential controls
use DTA/Final,clear
cap drop _x*
egen fe=group(fips year)
foreach v in cellphone marital lgb children adult race educa employ{
	cap tab `v', g(_x_`v')
}
tempfile temp1
save `temp1', replace

tempfile temp2
tempfile stacked


* Loop over outcomes and create outcome-specific dataset
foreach outcome in mental mental_ext physical poor badhealth cost concentration errands depressed {

* Loop over gender
foreach gender in trans cis {
	
	local i=0

	************** 1) Medicare **************

	* 1) Set up
	
	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1
	
	* Running variable and discontinuity
	g run = age-65
	g T = (run>=0)
	g rT = run * T
	
	* Control for fpl if run is age, control for age if run is fpl
	cap drop dummy
	xtile dummy=fpl [aw=_llcpwt],n(5)
	tab dummy, g(_x_fpl_age)

	* 2) Double machine-learning lasso select controls on full sample: dont penalize run, kink, jump, fixed effects
	xtset fe
	ivlasso `outcome' (_x* run rT) (insurance= T) [aw=_llcpwt], cluster(_psu) ///
		post(plasso) partial(run rT T) lopt(seed(19361938)) fe
	local xkeep = e(xselected)
	ds _x*,not
	local otherkeep=r(varlist)
	keep `xkeep' `otherkeep'
	
	* 3) Select MSE-optimal bandwidths; for cis, use trans bandwidth
	
	* Symetic, non-overlapping event window
	sum run if age>26, meanonly													// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric 
	
	* MSE Optimal bandwidth
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(`xkeep' i.fe)	///
				vce(cluster _psu) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local left65=min(e(h_mserd),`l')
		local right65=min(e(h_mserd),`l')
	}
	keep if run >= -`left65' & run <= `right65'

	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`left65') right(`right65')
	
	* 4) Stack Dataset
	g rd=`i'
	g rd_type = "jump"
	g rd_name = "Medicare"
	g bw_l = `left65'
	g bw_r = `right65'
	save `stacked', replace
	
	
	************** 2) ACA Age 26, Parent Insurance **************

	* 1) Set up
	
	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1
	
	* Running variable and discontiuiu
	g run = age-26
	g T = (run>=0)
	g rT = run * T
	
	* Control for fpl if run is age, control for age if run is fpl
	cap drop dummy
	xtile dummy=fpl [aw=_llcpwt],n(5)
	tab dummy, g(_x_fpl_age)
	
	* 2) Double machine-learning lasso select controls on full sample: dont penalize run, kink, jump, fixed effects
	xtset fe
	ivlasso `outcome' (_x* run rT) (insurance= T) [aw=_llcpwt], cluster(_psu) ///
		post(plasso) partial(run rT T) lopt(seed(19361938)) fe
	local xkeep = e(xselected)
	ds _x*,not
	local otherkeep=r(varlist)
	keep `xkeep' `otherkeep'

	* 3) Select MSE-optimal bandwidths; for cis, use trans bandwidth

	* Largest symetic, non-overlapping event window
	sum run if age<64, meanonly													// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric
	
	* MSE Optimal bandwidth
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(`xkeep' i.fe)	///
				vce(cluster _psu) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local left26=min(e(h_mserd),`l')
		local right26=min(e(h_mserd),`l')
	}
	keep if run >= -`left26' & run <= `right26'
	
	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`left26') right(`right26')

	* 4) Stack Dataset
	g rd=`i'
	g rd_type = "jump"
	g rd_name = "ACA 26"
	g bw_l = `left26'
	g bw_r = `right26'
	save `temp2', replace
	use `stacked', clear
	append using `temp2'
	save `stacked', replace
	
	
	************** 3) Medicaid **************

	* 1) Set up
	
	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1 &  !inlist(medicaid_FPL,.) & age<=64
	
	* Running variable and discontiuiu
	g run = fpl-medicaid_FPL
	g T = (run>=0)
	g rT = run * T
	
	* Control for fpl if run is age, control for age if run is fpl
	cap drop dummy
	xtile dummy=age [aw=_llcpwt],n(5)
	tab dummy, g(_x_fpl_age)
	
	* 2) Double machine-learning lasso select controls: do not penalize run, kink, jump or fixed effects
	xtset fe
	ivlasso `outcome' (_x* run rT) (insurance= T) [aw=_llcpwt], cluster(_psu) ///
		post(plasso) partial(run rT T) lopt(seed(19361938)) fe
	local xkeep = e(xselected)
	ds _x*,not
	local otherkeep=r(varlist)
	keep `xkeep' `otherkeep'

	* 3) Select MSE-optimal bandwidths; for cis, use trans bandwidth
	
	* Largest symetic, non-overlapping event window
	sum run if fpl<=300, meanonly												// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric
	
	* MSE Optimal bandwidth	
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(`xkeep' i.fe)	///
				vce(cluster _psu) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local leftmed=min(e(h_mserd),`l')
		local rightmed=min(e(h_mserd),`l')
	}
	keep if run >= -`leftmed' & run <= `rightmed'
	
	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`leftmed') right(`rightmed')
	
	* 4) Stack Dataset
	g rd=`i'
	g rd_type = "jump"
	g rd_name = "Medicaid"
	g bw_l = `leftmed'
	g bw_r = `rightmed'
	save `temp2', replace
	use `stacked', clear
	append using `temp2'
	save `stacked', replace

	
	
	
	
	************** 4) ACA 100 medicaid/medicare inelgible **************

	* 1) Set up
	
	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1  &  inlist(medicaid_FPL,.) & age<=64
	
	* Running variable and discontiuiu
	g run = fpl-100
	g T = (run>=0)
	g rT = run * T
	
	* Control for fpl if run is age, control for age if run is fpl
	cap drop dummy
	xtile dummy=age [aw=_llcpwt],n(5)
	tab dummy, g(_x_fpl_age)
	
	* 2) Double machine-learning lasso select controls: do not penalize run, kink, jump or fixed effects
	xtset fe
	ivlasso `outcome' (_x* run rT) (insurance= T) [aw=_llcpwt], cluster(_psu) ///
		post(plasso) partial(run rT T) lopt(seed(19361938)) fe
	local xkeep = e(xselected)
	ds _x*,not
	local otherkeep=r(varlist)
	keep `xkeep' `otherkeep'

	* 3) Select MSE-optimal bandwidths; for cis, use trans bandwidth
	
	* Largest symetic, non-overlapping event window
	sum run if fpl<133, meanonly												// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric
	
	* MSE Optimal bandwidth
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(`xkeep' i.fe)	///
				vce(cluster _psu) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local left100=min(e(h_mserd),`l')
		local right100=min(e(h_mserd),`l')
	}
	keep if run >= -`left100' & run <= `right100'
		
	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`left100') right(`right100')
	
	* 4) Stack Dataset
	g rd=`i'
	g rd_type = "jump"
	g rd_name = "ACA 100"
	g bw_l = `left100'
	g bw_r = `right100'
	save `temp2', replace
	use `stacked', clear
	append using `temp2'
	save `stacked', replace


	
	
	
	
	************** 5) ACA 133 medicaid/medicare inelgible **************

	* 1) Set up
	
	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1 &  inlist(medicaid_FPL,.) & age<=64
	
	* Running variable and discontiuiu
	g run = fpl-133
	g T = (run>=0)
	g rT = run * T
	
	* Control for fpl if run is age, control for age if run is fpl
	cap drop dummy
	xtile dummy=age [aw=_llcpwt],n(5)
	tab dummy, g(_x_fpl_age)	
	
	* 2) Double machine-learning lasso select controls: do not penalize run, kink, jump or fixed effects
	xtset fe
	ivlasso `outcome' (_x* run) (insurance= T rT) [aw=_llcpwt], cluster(_psu) ///
		post(plasso) partial(run rT T) lopt(seed(19361938)) fe
	local xkeep = e(xselected)
	ds _x*,not
	local otherkeep=r(varlist)
	keep `xkeep' `otherkeep'

	* 3) Select MSE-optimal bandwidths; for cis, use trans bandwidth

	* Largest symetic, non-overlapping event window
	sum run if fpl>=100 & fpl<300, meanonly										// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric
	
	* MSE Optimal bandwidth
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(`xkeep' i.fe)	///
				vce(cluster _psu) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local left133=min(e(h_mserd),`l')
		local right133=min(e(h_mserd),`l')
	}
	keep if run >= -`left133' & run <= `right133'
		
	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`left133') right(`right133')
	
	* 4) Stack Dataset
	g rd=`i'
	g rd_type = "both"
	g rd_name = "ACA 133"
	g bw_l = `left133'
	g bw_r = `right133'
	save `temp2', replace
	use `stacked', clear
	append using `temp2'
	save `stacked', replace
	
	
	************** 6) ACA 300 medicaid/medicare inelgible **************

	* 1) Set up
	
	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1 & age<=64
	
	* Running variable and discontiuiu
	g run = fpl-300
	g T = (run>=0)
	g rT = run * T
	
	* Control for fpl if run is age, control for age if run is fpl
	cap drop dummy
	xtile dummy=age [aw=_llcpwt],n(5)
	tab dummy, g(_x_fpl_age)		
	
	* 2) Double machine-learning lasso select controls: do not penalize run, kink, jump or fixed effects
	xtset fe
	ivlasso `outcome' (_x* run T) (insurance= rT) [aw=_llcpwt], cluster(_psu) ///
		post(plasso) partial(run rT T) lopt(seed(19361938)) fe
	local xkeep = e(xselected)
	ds _x*,not
	local otherkeep=r(varlist)
	keep `xkeep' `otherkeep'

	* 3) Select MSE-optimal bandwidths; for cis, use trans bandwidth

	* Largest symetic, non-overlapping event window
	sum run if fpl>=133 & fpl<400, meanonly										// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric
	
	* MSE Optimal bandwidth
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(`xkeep' i.fe)	///
		vce(cluster _psu) deriv(1) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local left300=min(e(h_mserd),`l')
		local right300=min(e(h_mserd),`l')
	}
	keep if run >= -`left300' & run <= `right300'
		
	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`left300') right(`right300')
	
	* 4) Stack Dataset
	g rd=`i'
	g rd_type = "kink"
	g rd_name = "ACA 300"
	g bw_l = `left300'
	g bw_r = `right300'
	save `temp2', replace
	use `stacked', clear
	append using `temp2'
	save `stacked', replace

	
	************** 7) ACA 400 medicaid/medicare inelgible **************

	* 1) Set up
	
	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1  & age<=64
	
	* Running variable and discontiuiu
	g run = fpl-400
	g T = (run>=0)
	g rT = run * T
	
	* Control for fpl if run is age, control for age if run is fpl
	cap drop dummy
	xtile dummy=age [aw=_llcpwt],n(5)
	tab dummy, g(_x_fpl_age)	
	
	* 2) Double machine-learning lasso select controls: do not penalize run, kink, jump or fixed effects
	xtset fe
	ivlasso `outcome' (_x* run rT) (insurance= T) [aw=_llcpwt], cluster(_psu) ///
		post(plasso) partial(run rT T) lopt(seed(19361938)) fe
	local xkeep = e(xselected)
	ds _x*,not
	local otherkeep=r(varlist)
	keep `xkeep' `otherkeep'

	* 3) Select MSE-optimal bandwidths; for cis, use trans bandwidth
	
	* Largest symetic, non-overlapping event window
	sum run if fpl>300, meanonly												// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric
	
	* MSE Optimal bandwidth
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(`xkeep' i.fe)	///
				vce(cluster _psu) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local left400=min(e(h_mserd),`l')
		local right400=min(e(h_mserd),`l')
	}
	keep if run >= -`left400' & run <= `right400'
	
	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`left400') right(`right400')
	
	* 4) Stack Dataset
	g rd=`i'
	g rd_type = "jump"
	g rd_name = "ACA 400"
	g bw_l = `left400'
	g bw_r = `right400'
	save `temp2', replace
	use `stacked', clear
	append using `temp2'
	save `stacked', replace
	
	
	************** Store Final Dataset **************
	
	foreach v of varlist _x* {
		replace `v'=0 if `v'==.
	}
	order rd* fips year run T rT bw_* _psu age fpl _llcpwt _weight mental physical poor badhealth ///
		cost concentration errands depressed _x*
	sort rd fips year run
	egen _psu_rd=group(_psu rd)
	compress
	save DTA/Stacked_`gender'_`outcome'_${kernel}, replace
	
}

}
