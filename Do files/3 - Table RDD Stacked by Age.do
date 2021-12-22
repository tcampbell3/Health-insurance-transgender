* Set up
global controls = "i.cellphone i.fpl_bins i.race i.marital#i.lgb i.children i.adult i.pregnant i.employ#i.educ"
global absorb = "i.fips#i.year#i.rd"
global kernel = "tri"

* Programs
do "Do Files/3 - RDD Programs"

	
***************************************
***************** Table ***************
***************************************

* Open Data
use DTA/Final, clear
eststo clear
quietly reg _llcpwt
eststo dummy

* Column Counter
local c=1

* Loop Columns
foreach outcome in mental physical poor badhealth cost concentration errands depressed{
foreach g in cis trans {
	
	* Row Counter
	global r=1
	global rows="" // blank row for "Mean . (SD)" label

	* Store Estimates
	est restore dummy
	eststo col`c'
	
	* Age 64
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	keep if rd==1
	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(1) cluster(_psu_rd) a(${absorb}) 
	_store_stacked , out(`outcome') c(`c')	
	
	* Age 26
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	keep if rd==2 & year <2020													// Remove due to covid

	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(1) cluster(_psu_rd) a(${absorb}) 
	_store_stacked , out(`outcome') c(`c')		
	
	* Stacked 2SLS
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	drop if year==2020 & rd==2													// Remove due to covid
	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(1) cluster(_psu_rd) a(${absorb})  
	_store_stacked , out(`outcome')  c(`c')	
	
	* Stacked LIML
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	drop if year==2020 & rd==2													// Remove due to covid
	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(1) cluster(_psu_rd) a(${absorb}) sub(liml)
	_store_stacked , out(`outcome') c(`c')	
	
	* Blank Row for space and titles
	estadd local blank=""
	
	* New column
	local col="`col' col`c'"
	local colpost="`colpost' & (`c')"
	local gender=proper("`g'")
	local gpost="`gpost' & `gender'"

	local c=`c'+1			
}
}


* Save Table
esttab `col' using Output/rd_stacked_age.tex, ///
	stats(${rows} outcome, 											///
		fmt( %010.0gc )															///
		label(																	///
		"\addlinespace[0.3cm] \underline{\textit{Age Cutoff: 65}}" 				///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 		
		"\addlinespace[0.3cm] \underline{\textit{Age Cutoff: 26}}" 				///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 		
		"\addlinespace[0.3cm] \underline{\textit{Stacked: 2SLS}}" 				///
			"\hspace{.25cm}Insurance" 											///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 		
		"\addlinespace[0.3cm] \underline{\textit{Stacked: LIML}}" 				///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 		
		"\addlinespace[0.3cm] \midrule Outcome"									/// 
			))																	///
	keep( ) replace nomtitles nonotes booktabs nogap nolines longtable	nolines nonum		///
	prehead(\begin{tabular}{l*{20}{x{1.7cm}}} \toprule) 										///
	posthead(`colpost' \\  `gpost' \\\midrule)  ///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA