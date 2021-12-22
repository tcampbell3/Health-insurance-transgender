********** Outcome Storage ************

cap program drop outcome
program outcome
	syntax [, y(varlist)]
	
	* Save outcome
	local o=proper("`y'")
	if "`o'"=="Mental"{
		local o="Mental days"
	}
	if "`o'"=="Physical"{
		local o="Physical days"
	}
	if "`o'"=="Poorhealth"{
		local o="Bad days"
	}
	if "`o'"=="Badhealth"{
		local o="Poor health"
	}
	cap estadd local outcome= "`o'"

	end


********** First Stage RD Table Storeage ************

cap program drop _store_first
program _store_first
	syntax [, bw(int 50) d(string) c(int 50) p(int 50) y(string)]
	
	* Store Instruments as locals
	local iv=""
	levelsof rd, clean
	local events = r(levels)
	foreach i in `events'{
		
		* RD type
		levelsof rd_type if rd==`i', clean
		local d=proper(r(levels))
		assert "`d'"=="Jump"|"`d'"=="Kink"|"`d'"=="Both"

		if "`d'"=="Jump"|"`d'"=="Both"{
			local iv="`iv' _T_star_`i'"
		}
		if "`d'"=="Kink"|"`d'"=="Both"{
			forvalues poly=1/`p'{
				local iv="`iv' _x_c_T_star_`i'_`poly'"
			}
		}
	}
	
	* Save locals FIRST STAGE
	estimates restore _ivreg2_insurance
	estimates replay _ivreg2_insurance
	foreach v in `iv'{
		local star`v'=""
		if _P[`v']<.1{
			local fstar`v' "^{*}"
		}
		if _P[`v']<.05{
			local fstar`v' "^{**}"
		}
		if _P[`v']<.01{
			local fstar`v' "^{***}"		
		}
		local b`v': di %10.3gc round(_b[`v'],.001)
		local fb`v' = trim("`b`v''")
		local se`v': di %10.3gc round(_se[`v'],.001)
		local fse`v' = trim("`se`v''")
	}
	test `iv'
	local f=r(F)
	local N=e(N)
	
	* Save locals REDUCED FORM
	RDD_stack `y' insuran (${controls})#i.rd [aw=_weight], cluster(_psu_rd) p(1) a(${absorb}) reduced
	foreach v in `iv'{
		local star`v'=""
		if _P[`v']<.1{
			local rstar`v' "^{*}"
		}
		if _P[`v']<.05{
			local rstar`v' "^{**}"
		}
		if _P[`v']<.01{
			local rstar`v' "^{***}"		
		}
		local b`v': di %10.3gc round(_b[`v'],.001)
		local rb`v' = trim("`b`v''")
		local se`v': di %10.3gc round(_se[`v'],.001)
		local rse`v' = trim("`se`v''")
	}

	* Open stored estimates
	est restore col`c'
	
	* Save First-stage beta and standard error for instruments
	foreach set in f r{
	foreach i in `events'{
		
		* RD type
		levelsof rd_type if rd==`i', clean
		local d=proper(r(levels))
		assert "`d'"=="Jump"|"`d'"=="Kink"|"`d'"=="Both"

		if "`d'"=="Jump"|"`d'"=="Both"{
			* First Stage beta
			estadd local row$r = "\$``set'b_T_star_`i''``set'star_T_star_`i''\$"
			global rows="$rows row$r"
			global r = $r + 1
			
			* First Stage Standard Error
			estadd local row$r = "(``set'se_T_star_`i'')"
			global rows="$rows row$r"
			global r = $r + 1
		}
		if "`d'"=="Kink"|"`d'"=="Both"{
			forvalues poly=1/`p'{
				* First Stage beta
				estadd local row$r = "\$``set'b_x_c_T_star_`i'_`poly''``set'star_x_c_T_star_`i'_`poly''\$"
				global rows="$rows row$r"
				global r = $r + 1
				
				* First Stage Standard Error
				estadd local row$r = "(``set'se_x_c_T_star_`i'_`poly'')"
				global rows="$rows row$r"
				global r = $r + 1
			}
		}
	}
		
	if "`set'"!="r"{
		global rows="$rows blank"
	}

	}
	
	* First-stage F statistic
	estadd scalar ffirst = round(`f',.1)	
	
	* Bandwidth
	cap estadd local bw = "MSE-optimal"	
	
	* Polynomial
	cap estadd scalar polynomial = `p'	
	
	* Kernal
	if "${kernel}"=="uni"{
		cap estadd local kernel = "Uniform"	
	}
	if "${kernel}"=="tri"{
		cap estadd local kernel = "Triangular"	
	}
	if "${kernel}"=="epa"{
		cap estadd local kernel = "Epanechnikov"	
	}
	
	* N
	cap estadd scalar samplesize = `N'

	end

	

******* Stacked RDD, centered at cutoff (zero) ********

cap program drop RDD_stack
program RDD_stack, rclass
	version 16
	syntax varlist(fv) [if] [in] [aw] [, cluster(varlist) p(int 50) a(string) sub(string) reduced]
	// "RDD outcome treatment [if] [in] [weight] [, run(running variable) c(cutoff) bw(bandwidth) p(polynomial) a(absorb) controls()]"
	
	* Local outcome (y) treatment (t) and controls (X)
	tokenize `varlist'
	local y `1'
	macro shift
	local t `1'
	macro shift
	local X `*'
	
	preserve
	cap drop _T*
	cap drop _x_c_*
	
	* Loop over each rd
	levelsof rd, clean
	local events = r(levels)
	foreach rd in `events'{
		
		* Type of discontuity
		levelsof rd_type if rd==`rd', clean		
		local rd_type = r(levels)
		
		* Jump
		g _T_star_`rd' = (run >= 0) * (rd==`rd')
		
		* Polynomial running variable and kink
		forvalues i = 1/`p'{
			g _x_c_r_`rd'_`i' = (run)^`i' * (rd==`rd')
			g _x_c_T_star_`rd'_`i' = _x_c_r_`rd'_`i' * _T_star_`rd' * (rd==`rd')
		}	
				
		* Local IV and Controls by RD type
		assert "`rd_type'"=="jump"|"`rd_type'"=="kink"|"`rd_type'"=="both"
		if "`rd_type'"=="jump"{
			local X = "`X' _x_c_r_`rd'* _x_c_T_star_`rd'*"	// Control for run and kink
			local iv = "`iv' _T_star_`rd'"					// Instrument is jump
		}
		if "`rd_type'"=="kink"{
			local X = "`X' _x_c_r_`rd'* _T_star_`rd'"		// Control for run and jump
			local iv = "`iv' _x_c_T_star_`rd'*"				// Instruments are kinks
		}
		if "`rd_type'"=="both"{
			local X = "`X' _x_c_r_`rd'*"					// Control for run
			local iv = "`iv' _T_star_`rd' _x_c_T_star_`rd'*"	// Instruments are jump and kinks
		}
	}
	
	* Estimate
	*ivreghdfe `y' `X' (`t'= `iv' ) `if' `in' [`weight' `exp'],  cluster(`cluster') absorb(`a') partial(`X') `sub'
	
	if "`reduced'"=="reduced"{
		reghdfe `y' `X' `iv' `if' `in' [`weight' `exp'],  old cluster(`cluster') absorb(`a')
	}
	else{
		reghdfe `y' `X' (`t'= `iv' ) `if' `in' [`weight' `exp'],  old cluster(`cluster') absorb(`a') subopt(`sub')
	}

	restore
	end

	

******* Stacked RDD Table Storage ********
	
cap program drop _store_stacked
program _store_stacked
	syntax [, out(varlist) c(int 50)]
	
	* Save locals
	if _P[insurance]<.1{
			local star "^{*}"
	}
	if _P[insurance]<.05{
			local star "^{**}"
	}
	if _P[insurance]<.01{
			local star "^{***}"		
	}
	local b: di %10.3gc round(_b[insurance],.001)	
	local b = trim("`b'")
	local se: di %10.3gc round(_se[insurance],.001)	
	local se = trim("`se'")
	local f=e(rkf)	// other option is cdf, which assumes iid standard errors
	local N=e(N)
	
	* Open stored estimates
	est restore col`c'
	
	* Treatment
	estadd local row$r = "\$`b'`star'\$"
	global rows="$rows row$r"
	global r = $r + 1
	
	* Standard Error
	estadd local row$r = "(`se')"
	global rows="$rows row$r"
	global r = $r + 1
	
	* First-stage F statistic
	estadd scalar row$r = round(`f',.1)	
	global rows="$rows row$r"
	global r = $r + 1	
	
	* N
	estadd scalar row$r = `N'
	global rows="$rows row$r"
	global r = $r + 1	

	* Outcome
	outcome, y(`out')

		
	end	
