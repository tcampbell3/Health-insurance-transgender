
cd "${path}"

********* MEDICARE ********

* Find trans-MSE optitam bandwidth
use DTA/Stacked_trans_mental_${kernel}, clear
keep if rd==1
foreach v in l r{
	sum bw_`v', meanonly
	local bw_`v' = r(mean)
}
local first: di 65-round(`bw_l')+1
local last: di 65+round(`bw_r')-1

* Medicare coverage rate
use DTA/CPS_Insurance,clear
g outcome=(mcare==1)
g run = age - 65
drop if run<-`bw_l' | run>`bw_r'  | now_mcare==0
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome age [aw=_weight],  rd(64.99999) savegraph(Output/Age_65_parents.pdf)  replace ///
	xtitle("Age", size(12pt)) ytitle("Medicare coverage rate",size(12pt)) xsize(8) xlabel(65(2)`first' 65(2)`last')
	
* Insurance Coverage Rate
use DTA/CPS_Insurance,clear
g outcome = inlist(depriv,1)|inlist(priv,1)|inlist(mcare,1)|inlist(mcaid,1)|inlist(champ,1)|inlist(hchamp,1)|inlist(hi_yn,1)|inlist(hi,1)|inlist(dephi,1)|inlist(out,1)|inlist(care,1)|inlist(caid,1)|inlist(oth,1)|inlist(othstper,1)
replace outcome = (cov==1) if !inlist(cov,.)
g run = age - 65
drop if run<-`bw_l' | run>`bw_r' 
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome age [aw=_weight],  rd(64.99999) savegraph(Output/Age_65_cps.pdf)  replace ///
	xtitle("Age",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(8) xlabel(65(2)`first' 65(2)`last')

* Insurance Coverage Rate
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="Medicare"
binscatter insurance age [aw=_weight],  rd(64.99999) savegraph(Output/Age_65_brfss.pdf)  replace ///
	xtitle("Age",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(8) xlabel(65(2)`first' 65(2)`last')
	
	

********* Parents ********

* Find trans-MSE optitam bandwidth
use DTA/Stacked_trans_mental_${kernel}, clear
keep if rd==2
foreach v in l r{
	sum bw_`v', meanonly
	local bw_`v' = r(mean)
}
local first: di 26-round(`bw_l')+2
local last: di 26+round(`bw_r')-2

* Other private coverage rate
use DTA/CPS_Insurance,clear
g outcome=( now_ownpriv==2)
g run = age - 26
drop if run<-`bw_l' | run>`bw_r' | now_ownpriv==0 | now_priv!=1 | age<18
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome age [aw=_weight],  rd(25.99999) savegraph(Output/Age_26_parents.pdf)  replace ///
	xtitle("Age",size(12pt)) ///
	ytitle("Ratio of those covered by another's private coverage" "to any private coverage",size(12pt)) ///
	xsize(8) xlabel(26(4)`first' 26(4)`last')
	
* Insurance Coverage Rate
use DTA/CPS_Insurance,clear
g outcome = inlist(depriv,1)|inlist(priv,1)|inlist(mcare,1)|inlist(mcaid,1)|inlist(champ,1)|inlist(hchamp,1)|inlist(hi_yn,1)|inlist(hi,1)|inlist(dephi,1)|inlist(out,1)|inlist(care,1)|inlist(caid,1)|inlist(oth,1)|inlist(othstper,1)
replace outcome = (cov==1) if !inlist(cov,.)
g run = age - 26
drop if run<-`bw_l' | run>`bw_r'  | age<18
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome age [aw=_weight],  rd(25.99999) savegraph(Output/Age_26_cps.pdf)  replace ///
	xtitle("Age",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(8) xlabel(26(4)`first' 26(4)`last')

* Insurance Coverage Rate
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 26"
binscatter insurance age [aw=_weight],  rd(25.99999) savegraph(Output/Age_26_brfss.pdf)  replace ///
	xtitle("Age",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(8) xlabel(26(4)`first' 26(4)`last')

********* MEDICAID ********

* Find trans-MSE optitam bandwidth
use DTA/Stacked_trans_mental_${kernel}, clear
keep if rd==3
foreach v in l r{
	sum bw_`v', meanonly
	local bw_`v' = r(mean)
}

* Medicaid Coverage Rate
use DTA/CPS_Insurance,clear
g medicaid=(caid==1)
g run = fpl - medicaid_FPL
drop if run<-`bw_l' | run>`bw_r' |age<27|age>64
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter medicaid run [aw=_weight],  rd(-.0000001)  savegraph(Output/medicaid_fpl.pdf)  ///
	replace xtitle("Federal poverty level centered at medicaid eligibility",size(12pt)) ///
	ytitle("Medicaid coverage rate",size(12pt)) ///
	xsize(8) xlabel(0(6)-33 0(6)33)

* Insurance Coverage Rate
use DTA/CPS_Insurance,clear
g outcome = inlist(depriv,1)|inlist(priv,1)|inlist(mcare,1)|inlist(mcaid,1)|inlist(champ,1)|inlist(hchamp,1)|inlist(hi_yn,1)|inlist(hi,1)|inlist(dephi,1)|inlist(out,1)|inlist(care,1)|inlist(caid,1)|inlist(oth,1)|inlist(othstper,1)
replace outcome = (cov==1) if !inlist(cov,.)
g run = fpl - medicaid_FPL
drop if run<-`bw_l' | run>`bw_r' |age<27|age>64
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome run [aw=_weight],  rd(-.0000001)  savegraph(Output/medicaid_fpl_cps.pdf)  ///
	replace xtitle("Federal poverty level centered at medicaid eligibility",size(12pt)) ///
	ytitle("Insurance coverage rate",size(12pt)) ///
	xsize(8) xlabel(0(6)-33 0(6)33)

* Insurance Coverage Rate (BRFSS)
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="Medicaid"
binscatter insurance run [aw=_weight],  rd(-.0000001) savegraph(Output/medicaid_fpl_brfss.pdf)  ///
	replace xtitle("Federal poverty level centered at medicaid eligibility",size(12pt)) ///
	ytitle("Insurance coverage rate",size(12pt)) ///
	xsize(8) xlabel(0(6)-33 0(6)33)


********* Market Coverage 100 ********

* Find trans-MSE optitam bandwidth
use DTA/Stacked_trans_mental_${kernel}, clear
keep if rd==4
foreach v in l r{
	sum bw_`v', meanonly
	local bw_`v' = r(mean)
}
local first: di 100-round(`bw_l')+3
local last: di 100+round(`bw_r')-3

* Cap
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 100"
binscatter cap fpl [aw=_weight],  rd(99.999999) savegraph(Output/cap_100.pdf)  replace ///
	xtitle("Federal poverty level",size(12pt)) ytitle("Insurance premium cap" "(% of family income)",size(12pt)) ///
	xsize(6) ///
	xlabel(100(6)`first' 100(6)133)

* Insurance Coverage Rate
use DTA/CPS_Insurance,clear
keep if (medicaid_FPL<100|medicaid_FPL==.) & age<=64&age>=27 & fpl<133
g outcome = inlist(depriv,1)|inlist(priv,1)|inlist(mcare,1)|inlist(mcaid,1)|inlist(champ,1)|inlist(hchamp,1)|inlist(hi_yn,1)|inlist(hi,1)|inlist(dephi,1)|inlist(out,1)|inlist(care,1)|inlist(caid,1)|inlist(oth,1)|inlist(othstper,1)
replace outcome = (cov==1) if !inlist(cov,.)
g run = fpl - 100
drop if run<-`bw_l' | run>`bw_r' 
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome fpl [aw=_weight],  rd(99.999999) savegraph(Output/FPL_100_cps.pdf)  ///
	replace xtitle("Federal poverty level",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(6) ///
	xlabel(100(6)`first' 100(6)133)

* Insurance Coverage Rate
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 100"
binscatter insurance fpl [aw=_weight],  rd(99.999999) savegraph(Output/FPL_100_brfss.pdf)  ///
	replace xtitle("Federal poverty level",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(6) ///
	xlabel(100(6)`first' 100(6)133)


	
********* Market Coverage 133 ********


* Find trans-MSE optitam bandwidth
use DTA/Stacked_trans_mental_${kernel}, clear
keep if rd==5
foreach v in l r{
	sum bw_`v', meanonly
	local bw_`v' = r(mean)
}
local first: di 133-round(`bw_l')
local last: di 133+round(`bw_r')

* Cap
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 133"
binscatter cap fpl [aw=_weight],  rd(132.999999) savegraph(Output/cap_133.pdf)  replace ///
	xtitle("Federal poverty level",size(12pt)) ytitle("Insurance premium cap" "(% of family income)",size(12pt)) xsize(6) ///
	xlabel(133(3)`first' 133(3)`last')

* Insurance Coverage Rate
use DTA/CPS_Insurance,clear
keep if (medicaid_FPL<100|medicaid_FPL==.) & age<=64&age>=27 & fpl>100 & fpl<300
g outcome = inlist(depriv,1)|inlist(priv,1)|inlist(mcare,1)|inlist(mcaid,1)|inlist(champ,1)|inlist(hchamp,1)|inlist(hi_yn,1)|inlist(hi,1)|inlist(dephi,1)|inlist(out,1)|inlist(care,1)|inlist(caid,1)|inlist(oth,1)|inlist(othstper,1)
replace outcome = (cov==1) if !inlist(cov,.)
g run = fpl - 133
drop if run<-`bw_l' | run>`bw_r' 
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome fpl [aw=_weight],  rd(132.99) savegraph(Output/FPL_133_cps.pdf)  ///
	replace xtitle("Federal poverty level",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(6) 	 ///
	xlabel(133(3)`first' 133(3)`last')

* Insurance Coverage Rate
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 133"& medicaid_FPL==.
binscatter insurance fpl [aw=_weight],  rd(132.99) savegraph(Output/FPL_133_brfss.pdf)  ///
	replace xtitle("Federal poverty level",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(6) ///
	xlabel(133(3)`first' 133(3)`last')

	
	
********* Market Coverage 300 ********

* Find trans-MSE optitam bandwidth
use DTA/Stacked_trans_mental_${kernel}, clear
keep if rd_name=="ACA 300"
foreach v in l r{
	sum bw_`v', meanonly
	local bw_`v' = r(mean)
}
local first: di 300-round(`bw_l')
local last: di 300+round(`bw_r')

* Cap
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 300"
binscatter cap fpl [aw=_weight],  rd(299.999999) savegraph(Output/cap_300.pdf)  replace ///
	xtitle("Federal poverty level",size(12pt)) ytitle("Insurance premium cap" "(% of family income)",size(12pt)) xsize(6) ///
	xlabel(300(10)`first' 300(10)`last')

* Insurance Coverage Rate
use DTA/CPS_Insurance,clear
keep if (medicaid_FPL<100|medicaid_FPL==.) & age<=64&age>=27 & fpl>133 & fpl<400
g outcome = inlist(depriv,1)|inlist(priv,1)|inlist(mcare,1)|inlist(mcaid,1)|inlist(champ,1)|inlist(hchamp,1)|inlist(hi_yn,1)|inlist(hi,1)|inlist(dephi,1)|inlist(out,1)|inlist(care,1)|inlist(caid,1)|inlist(oth,1)|inlist(othstper,1)
replace outcome = (cov==1) if !inlist(cov,.)
g run = fpl - 300
drop if run<-`bw_l' | run>`bw_r' 
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome fpl [aw=_weight],  rd(299.99) savegraph(Output/FPL_300_cps.pdf)  ///
	replace xtitle("Federal poverty level",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(6) ///
	xlabel(300(10)`first' 300(10)`last')

* Insurance Coverage Rate
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 300"
binscatter insurance fpl [aw=_weight],  rd(299.99) savegraph(Output/FPL_300_brfss.pdf)  ///
	replace xtitle("Federal poverty level",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(6) ///
	xlabel(300(10)`first' 300(10)`last')
			


********* Market Coverage 400 ********

* Find trans-MSE optitam bandwidth
use DTA/Stacked_trans_mental_${kernel}, clear
keep if rd==7
foreach v in l r{
	sum bw_`v', meanonly
	local bw_`v' = r(mean)
}
local first: di 400-round(`bw_l')
local last: di 400+round(`bw_r')

* Cap
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 400"
binscatter cap fpl [aw=_weight],  rd(399.999999) savegraph(Output/cap_400.pdf)  replace ///
	xtitle("Federal poverty level",size(12pt)) ytitle("Insurance premium cap" "(% of family income)",size(12pt)) xsize(6) ///
	xlabel(400(10)`first' 400(10)`last')

* Insurance Coverage Rate
use DTA/CPS_Insurance,clear
keep if (medicaid_FPL<100|medicaid_FPL==.) & age<=64&age>=27 & fpl>300
g outcome = inlist(depriv,1)|inlist(priv,1)|inlist(mcare,1)|inlist(mcaid,1)|inlist(champ,1)|inlist(hchamp,1)|inlist(hi_yn,1)|inlist(hi,1)|inlist(dephi,1)|inlist(out,1)|inlist(care,1)|inlist(caid,1)|inlist(oth,1)|inlist(othstper,1)
replace outcome = (cov==1) if !inlist(cov,.)
g run = fpl - 400
drop if run<-`bw_l' | run>`bw_r' 
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome fpl [aw=_weight],  rd(399.99) savegraph(Output/FPL_400_cps.pdf)  ///
	replace xtitle("Federal poverty level",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(6) ///
	xlabel(400(10)`first' 400(10)`last')
	
* Insurance Coverage Rate
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 400"
binscatter insurance fpl [aw=_weight],  rd(399.99) savegraph(Output/FPL_400_brfss.pdf)  ///
	replace xtitle("Federal poverty level",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(6) ///
	xlabel(400(10)`first' 400(10)`last')
			







