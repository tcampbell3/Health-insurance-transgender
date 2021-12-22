set seed 19361938
mata: rseed(19361938)
global kernel = "`1'"

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


* Define controls
use DTA/Final,clear
cap drop _x*
egen fe=group(fips year)
fasterxtile fpl_bins=fpl [aw=_llcpwt],n(5)
fasterxtile fpl_bins_brfss=fpl_brfss [aw=_llcpwt],n(5)
foreach v in cellphone marital lgb children adult race educa employ fpl_bins fe{
	cap tab `v', g(_x_`v')
}
tempfile temp1
save `temp1', replace

tempfile temp2
tempfile stacked


* Loop over outcomes and create outcome-specific dataset
foreach outcome in mental physical poor badhealth cost concentration errands depressed {

* Loop over gender
foreach gender in trans cis {
	
	local i=0

	************** 1) Medicare **************
	
	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1
	
	* Running variable and discontinuity
	g run = age-65
	g T = (run>=0)
	g rT = run * T
	
	* Symetic, non-overlapping event window
	sum run if age>26, meanonly													// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric 
	
	* MSE Optimal bandwidth
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(_x*)	///
				vce(cluster _psu) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local left65=min(e(h_mserd),`l')
		local right65=min(e(h_mserd),`l')
	}
	keep if run >= -`left65' & run <= `right65'

	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`left65') right(`right65')
	
	* Stack Dataset
	g rd=`i'
	g rd_type = "jump"
	g rd_name = "Medicare"
	g bw_l = `left65'
	g bw_r = `right65'
	save `stacked', replace
	
	
	************** 2) ACA Age 26, Parent Insurance **************

	* Open
	local i=`i'+1
	use `temp1', clear
	keep if `gender'==1
	
	* Running variable and discontiuiu
	g run = age-26
	g T = (run>=0)
	g rT = run * T

	* Largest symetic, non-overlapping event window
	sum run if age<64, meanonly													// non-overlapping
	local l = min(abs(r(min)),r(max))											// symetric
	
	* MSE Optimal bandwidth
	if "`gender'"=="trans"{
		xi: rdbwselect `outcome' run, weights(_llcpwt) fuzzy(insurance) covs(_x*)	///
				vce(cluster _psu) scaleregul(0) kernel(${kernel}) bwcheck(`l')	// ensure largest sym bw checked
		local left26=min(e(h_mserd),`l')
		local right26=min(e(h_mserd),`l')
	}
	keep if run >= -`left26' & run <= `right26'
	
	* Kernel weights
	kernel_weight , kernel(${kernel}) left(`left26') right(`right26')

	* Stack Dataset
	g rd=`i'
	g rd_type = "jump"
	g rd_name = "ACA 26"
	g bw_l = `left26'
	g bw_r = `right26'
	save `temp2', replace
	use `stacked', clear
	append using `temp2'
	save `stacked', replace
	
	
	************** Store Final Dataset **************
	
	foreach v of varlist _x* {
		replace `v'=0 if `v'==.
	}
	order rd* fips year run T rT bw_* _psu age fpl* _llcpwt _weight mental physical poor badhealth ///
		cost concentration errands depressed _x*
	sort rd fips year run
	egen _psu_rd=group(_psu rd)
	drop _x*
	compress
	save DTA/Stacked_`gender'_`outcome'_${kernel}, replace
	
}

}

* Exit stata
exit, clear STATA