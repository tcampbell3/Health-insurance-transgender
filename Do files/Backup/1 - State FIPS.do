
* State fips and abbreviations
import excel "Data\fips_codes.xls", sheet("cqr_universe_fixedwidth_all") firstrow clear
rename StateFIP* fips
rename StateAbb* stabb
keep stabb fips
drop if stabb=="PR"
duplicates drop
destring fips, replace
compress
save "DTA\state_fips.dta", replace

* State names
import delimited "Data\state_abb.csv", varnames(1) clear 
tempfile temp
save `temp',replace
use "DTA\state_fips.dta", clear
merge 1:1 stabb using `temp', nogen
save "DTA\state_fips.dta", replace
