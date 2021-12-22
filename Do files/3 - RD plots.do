cd "${path}"
forvalues rd=1/2{

	* Open full set of data
	use DTA/Stacked_cis_mental_${kernel}, clear
	append using DTA/Stacked_trans_mental_${kernel}
	keep if inlist(rd,`rd') & !inlist(_weight,0,.)
	g married = inlist(marital,1)
	g employed = inlist(employ1,1)
	if "`1'" == "restricted"{
		sum run, meanonly
		drop if abs(run)>r(max)/2
		local r = "_restricted"
		local xlab=1
	}
	else{
		local xlab=2
	}

	* Store age cutoffs
	sum age if inlist(run,0), meanonly
	local cutoff=r(mean)
	sum age, meanonly
	local first = r(min)
	local last = r(max)

	* Estimate discontuity
	reg ${y} run T rT [aw=_weight], vce(cluster _psu) 
	lincom T
	local beta = trim("`: display %10.3f r(estimate)'")
	local se =trim("`: display %10.3f r(se)'")
	local jump = "Jump discontinuity = `beta' (`se')"
	if r(estimate)>0{															// change position on figure
		local pos = 11
	}
	else{
		local pos = 1
	}
	
	* Continuous running variable for nice looking figure
	gcollapse (mean) ${y} [aw=_weight], by(age)
	expand 100 
	gsort age
	bys age: g _age=age+(_n-1)/100
	drop if _age>`last'
	local N=_N+2
	set obs `N'
	local d = _N-1
	replace _age = `first'-.25 in `d'
	local d = _N
	replace _age = `last'+.25 in `d'
	g run = _age-`cutoff'
	g T = run >=0
	g rT = T * run

	* Prediction
	predict b, xb
	predict se, stdp
	g ub = b + 1.967*se 
	g lb = b - 1.967*se 
	bys age: replace ${y} = . if _n>1

	* Final figure
	twoway 	(rarea ub lb _age if run<0, sort fcolor(midblue%45) lc(midblue%0)) 		///
			(line b _age if run<0, lp(solid) lc(midblue) lw(thick))					///			
			(rarea ub lb _age if run>=0, sort fcolor(red%45) lc(red%0)) 			///
			(line b _age if run>=0, lp(solid) lc(red) lw(thick))					///
			(scatter ${y} age, m(D) msize(large) mc(gray%80) mlc(gray%0))	///
			, xline(`cutoff', lp(dash) lc(gray%80)) xlabel(`first'(`xlab')`last' `cutoff')	///
			xtitle(Age) ytitle("${title1}" "${title2}") 							///
			legend(pos(`pos') ring(0) size(medsmall) order(20 "") subtitle("`jump'", size(medsmall) position(11))) 
	graph export "Output/jump_${y}_`rd'`r'.pdf", replace	

}