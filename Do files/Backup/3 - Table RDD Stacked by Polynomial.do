* Set up
global controls = "c._x*"
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
	
	* Polynomial Degree 1
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	keep if inlist(rd,1,2)													// age dis. only
	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(1) cluster(_psu_rd) a(${absorb}) 
	_store_stacked , out(`outcome') c(`c')	
	
	* Polynomial Degree 2
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	keep if inlist(rd,1,2)													// age dis. only
	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(2) cluster(_psu_rd) a(${absorb})
	_store_stacked , out(`outcome') c(`c')		
	
	* Polynomial Degree 3
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	keep if inlist(rd,1,2)													// age dis. only
	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(3) cluster(_psu_rd) a(${absorb}) 
	_store_stacked , out(`outcome') c(`c')	
	
	* Polynomial Degree 4
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	keep if inlist(rd,1,2)													// age dis. only
	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(4) cluster(_psu_rd) a(${absorb}) 
	_store_stacked , out(`outcome') c(`c')	
	
	* Polynomial Degree 5
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	keep if inlist(rd,1,2)													// age dis. only
	global rows="$rows blank"
	RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
		p(5) cluster(_psu_rd) a(${absorb}) 
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
esttab `col' using Output/rd_stacked_polynomial.tex, ///
	stats(${rows} outcome , 											///
		fmt( %010.0gc )															///
		label(																	///
		"\addlinespace[0.3cm] \underline{\textit{Polynomial degree: 1}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 		
		"\addlinespace[0.3cm] \underline{\textit{Polynomial degree: 2}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Polynomial degree: 3}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Polynomial degree: 4}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Polynomial degree: 5}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \midrule Outcome"									/// 
			))																	///
	keep( ) replace nomtitles nonotes booktabs nogap nolines longtable	nolines nonum	///
	prehead(\begin{tabular}{l*{20}{x{1.7cm}}} \toprule) 						///
	posthead(`colpost' \\  `gpost' \\\midrule) 									///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA