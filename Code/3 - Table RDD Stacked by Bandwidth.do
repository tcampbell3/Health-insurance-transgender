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
foreach g in cis trans {
forvalues bw = 0/5{
	
	* Row Counter
	global r=1
	global rows="" // blank row for "Mean . (SD)" label
	
	* Bandwidths
	local bw_age = `bw'
	local bw_fpl = `bw'*2
	
	* Store Estimates
	est restore dummy
	eststo col`c'
	
	* Loop over outcome rows
	foreach outcome in  mental physical poor badhealth cost concentration errands depressed{
		use DTA/Stacked_`g'_`outcome'_${kernel}, clear
		keep if inlist(rd,1,2)													// age dis. only
		replace bw_l = bw_l-`bw_age' if inlist(rd_name, "ACA 26", "Medicare")
		replace bw_l = bw_l-`bw_fpl' if inlist(rd_name, "ACA 100", "ACA 133", "ACA 300", "ACA 400", "Medicaid")
		replace bw_r = bw_r-`bw_age' if inlist(rd_name, "ACA 26", "Medicare")
		replace bw_r = bw_r-`bw_fpl' if inlist(rd_name, "ACA 100", "ACA 133", "ACA 300", "ACA 400", "Medicaid")
		keep if run<=bw_r & run>= -bw_l
		global rows="$rows blank"
		RDD_stack `outcome' insurance (${controls})#i.rd   [aw=_weight] if `g'==1 ,	///
			p(1) cluster(_psu_rd) a(${absorb}) 
		_store_stacked , out(`outcome') c(`c')	
	}	
	
	* Blank Row for space and titles
	estadd local blank=""
	
	* Store bandwidths
	estadd scalar bw_age = `bw_age'
	estadd scalar bw_fpl = `bw_fpl'
	
	* New column
	local col="`col' col`c'"
	local colpost="`colpost' & (`c')"
	local gender=proper("`g'")
	local gpost="`gpost' & `gender'"

	local c=`c'+1			
}
}


* Save Table
esttab `col' using Output/rd_stacked_bandwidth.tex, ///
	stats(${rows} bw_age bw_fpl, 												///
		fmt( %010.0gc )															///
		label(																	///
		"\addlinespace[0.3cm] \underline{\textit{Poor mental health days over last 30}}" 	///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Poor physical health days over last 30}}" 	///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Poor health days over last 30}}" 	///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Poor health in general}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 			
		"\addlinespace[0.3cm] \underline{\textit{Couldn't see doctor due to cost}}"		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Difficult concentrating due to health}}" ///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 		
		"\addlinespace[0.3cm] \underline{\textit{Difficult errands due to health}}" ///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Told they have depressive disorder}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}First-stage F"					/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \midrule Age bandwidth reduction"							/// 
		"\addlinespace[0.1cm]Federal poverty level bandwidth reduction"					/// 		
		))																	///
	keep( ) replace nomtitles nonotes booktabs nogap nolines longtable	nolines nonum		///
	prehead(\begin{tabular}{l*{20}{x{1.7cm}}} \toprule) 										///
	posthead(`colpost' \\  `gpost' \\\midrule)  ///
	postfoot(\bottomrule \end{tabular}) 


* Exit stata
exit, clear STATA