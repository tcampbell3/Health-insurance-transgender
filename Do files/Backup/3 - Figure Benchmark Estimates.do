* Set up log file
cd "${path}"
cap log close 
log using "Output/session_${kernel}", replace

* Programs
do "Do Files/3 - RDD Programs"

* Open Data and Create variables to fill with estimates
use DTA/Final, clear
g est=.
g y =. 
g x =.
g outcome=""
g gender=.

* Loop Estimates for 30 day variables
local i=1
local j=1
foreach outcome in poor physical mental{
foreach g in cis trans {
	
	* Stacked 2SLS
	preserve
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	if lower("${age}")=="yes"{
		keep if inlist(rd,1,2)
	}
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(1) cluster(_psu_rd) a(${absorb})
	restore 
	
	replace est=_b[insurance] in `i'
	replace x=_b[insurance]-invttail(e(df_r),.975)*_se[insurance] in `i'
	replace outcome="`outcome'" in `i'
	replace gender=`g' in `i'	
	replace y=`j' in `i'
	local i=`i'+1
	
	replace est=_b[insurance] in `i'
	replace x=_b[insurance]+invttail(e(df_r),.975)*_se[insurance] in `i'
	replace outcome="`outcome'" in `i'
	replace gender=`g' in `i'
	replace y=`j' in `i'
	local i=`i'+1
	local j=`j'+1
	
}
local j=`j'+1	// add space between var
}

* Graph (index is y axis)
twoway (line y x if y==1,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==2,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==4,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==5,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==7,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==8,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(scatter y est if gender==1,  mfc("85 205 252") mlc(black*.7) ms(D) msiz(medlarge)) ///
(scatter y est if gender==0,  mfc("247 168 184") mlc(black*.7) ms(D) msiz(medlarge)) ///
, ymlabel(1.7 "Bad health" 1.3 "days     " 4.7 "Bad physical" 4.3 "health days " 7.7 "Bad mental" 7.3 "health days", labsize(medsmall) notick) ///
ylabel(0 " " 3 " " 6 " " 9 " ") ///
legend( row(1) order(2 "Transgender" 1 "Cisgender") pos(6)) 							///
scheme(plotplain) ytitle("") xline(0, lcolor(grey*.6) lp(dash)) xtitle("") ysize(10)

* Save
graph export "Output/Estimates_30_day_${kernel}_${age}.pdf", replace		

* Graph with large font for presentation
twoway (line y x if y==1,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==2,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==4,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==5,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==7,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==8,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(scatter y est if gender==1,  mfc("85 205 252") mlc(black*.7) ms(D) msiz(medlarge)) ///
(scatter y est if gender==0,  mfc("247 168 184") mlc(black*.7) ms(D) msiz(medlarge)) ///
, ymlabel(1.7 "Bad health" 1.3 "days     " 4.7 "Bad physical" 4.3 "health days " 7.7 "Bad mental" 7.3 "health days", labsize(huge) notick) ///
ylabel(0 " " 3 " " 6 " " 9 " ") xlab(, labsize(huge)) ///
legend( row(1) order(2 "Trans" 1 "Cis") pos(6) size(*3) symx(*2))  	///
scheme(plotplain) ytitle("") xline(0, lcolor(grey*.6) lp(dash)) xtitle("") ysize(10)

* Save
graph export "Output/Estimates_30_day_${kernel}_${age}_bigfont.pdf", replace	




* Open Data and Create variables to fill with estimates
use DTA/Final, clear
g est=.
g y =. 
g x =.
g outcome=""
g gender=.

* Loop Estimates for 30 day variables
local i=1
local j=1
foreach outcome in depressed errands concentration cost badhealth{
foreach g in cis trans {
	
	* Stacked 2SLS
	preserve
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
		if lower("${age}")=="yes"{
		keep if inlist(rd,1,2)
	}
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(1) cluster(_psu_rd) a(${absorb})
	restore
	
	replace est=_b[insurance] in `i'
	replace x=_b[insurance]-invttail(e(df_r),.975)*_se[insurance] in `i'
	replace outcome="`outcome'" in `i'
	replace gender=`g' in `i'	
	replace y=`j' in `i'
	local i=`i'+1
	
	replace est=_b[insurance] in `i'
	replace x=_b[insurance]+invttail(e(df_r),.975)*_se[insurance] in `i'
	replace outcome="`outcome'" in `i'
	replace gender=`g' in `i'
	replace y=`j' in `i'
	local i=`i'+1
	local j=`j'+1
	
}
local j=`j'+1	// add space between var
}

* Graph (index is y axis)
twoway (line y x if y==1, color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==2,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==4, color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==5,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==7,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==8,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==10, color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==11,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==13, color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==14,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(scatter y est if gender==1,  mfc("85 205 252") mlc(black*.7) ms(D) msiz(medlarge)) ///
(scatter y est if gender==0,  mfc("247 168 184") mlc(black*.7) ms(D) msiz(medlarge)) ///
, ymlabel(1 "                    " 1.7 "Depressive" 1.3 "disorder  " 4.9 "Difficulty   " 4.5 "doing errands" 4.1 "due to health" 7.9 "Difficulty   " 7.5 "concentrating" 7.1 "due to health" 10.7 "Can't see doctor" 10.3 "due to cost    " 13.7 "Poor health in" 13.3 "general     ", labsize(medsmall) notick) ///
ylabel(0 " " 3 " " 6 " " 9 " " 12 " " 15 " ") ///
legend( row(1) order(1 "Cisgender" 2 "Transgender") pos(6)) 							///
scheme(plotplain) ytitle("") xline(0, lcolor(grey*.6) lp(dash)) xtitle("") ysize(10)

* Save
graph export "Output/Estimates_discrete_${kernel}_${age}.pdf", replace		

* Graph (index is y axis)
twoway (line y x if y==1, color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==2,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==4, color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==5,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==7,  color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==8,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==10, color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==11,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(line y x if y==13, color("85 205 252") lcolor("85 205 252") lp(solid) lw(thick)) ///
(line y x if y==14,  color("247 168 184") lcolor("247 168 184") lp(solid) lw(thick)) ///
(scatter y est if gender==1,  mfc("85 205 252") mlc(black*.7) ms(D) msiz(medlarge)) ///
(scatter y est if gender==0,  mfc("247 168 184") mlc(black*.7) ms(D) msiz(medlarge)) ///
, ymlabel(1 "                    " 1.9 "Depressive" 1.1 "disorder  " 5.3 "Difficulty   " 4.5 "doing errands" 3.7 "due to health" 8.3 "Difficulty   " 7.5 "concentrating" 6.7 "due to health" 11.3 "Can't     " 10.5 "see doctor " 9.7 "due to cost " 13.9 "Poor health" 13.1 "in general ", labsize(huge) notick) ///
ylabel(0 " " 3 " " 6 " " 9 " " 12 " " 15 " ") xlab(, labsize(huge)) 			///
legend( row(1) order(2 "Trans" 1 "Cis") pos(6) size(*3) symx(*2))  				///
scheme(plotplain) ytitle("") xline(0, lcolor(grey*.6) lp(dash)) xtitle("") ysize(10)

* Save
graph export "Output/Estimates_discrete_${kernel}_${age}_bigfont.pdf", replace		

* Save log file
translate "Output/session_${kernel}.smcl" "Output/session_${kernel}_${age}.pdf", replace
log close 