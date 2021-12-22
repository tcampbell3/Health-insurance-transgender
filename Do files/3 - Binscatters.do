
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
keep if rd==2 & year < 2020
foreach v in l r{
	sum bw_`v', meanonly
	local bw_`v' = r(mean)
}
local first: di 26-round(`bw_l')+1
local last: di 26+round(`bw_r')-1

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
	xsize(8) xlabel(26(1)`first' 26(1)`last')
	
* Insurance Coverage Rate
use DTA/CPS_Insurance,clear
g outcome = inlist(depriv,1)|inlist(priv,1)|inlist(mcare,1)|inlist(mcaid,1)|inlist(champ,1)|inlist(hchamp,1)|inlist(hi_yn,1)|inlist(hi,1)|inlist(dephi,1)|inlist(out,1)|inlist(care,1)|inlist(caid,1)|inlist(oth,1)|inlist(othstper,1)
replace outcome = (cov==1) if !inlist(cov,.)
g run = age - 26
drop if run<-`bw_l' | run>`bw_r'  | age<18
g _weight = max( 0 , 1/2) / `bw_l' * marsupwt if run<0
replace _weight = max( 0 , 1/2) / `bw_r' * marsupwt if run>=0
binscatter outcome age [aw=_weight],  rd(25.99999) savegraph(Output/Age_26_cps.pdf)  replace ///
	xtitle("Age",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(8) xlabel(26(1)`first' 26(1)`last')

* Insurance Coverage Rate
use DTA/Stacked_cis_mental_${kernel}, clear
append using DTA/Stacked_trans_mental_${kernel}
keep if rd_name=="ACA 26"
binscatter insurance age [aw=_weight],  rd(25.99999) savegraph(Output/Age_26_brfss.pdf)  replace ///
	xtitle("Age",size(12pt)) ytitle("Insurance coverage rate",size(12pt)) xsize(8) xlabel(26(1)`first' 26(1)`last')

