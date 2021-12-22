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
	global rows="" 

	* Store Estimates
	est restore dummy
	eststo col`c'
	
	* Stacked 2SLS
	global rows="$rows blank"
	use DTA/Stacked_`g'_`outcome'_${kernel}, clear
	keep if inlist(rd,1,2)
	RDD_stack `outcome' insuran (${controls})#i.rd [aw=_weight], cluster(_psu_rd) p(1) a(${absorb})  sub(first sfirst savefirst)
	_store_first, p(1) c(`c') y("`outcome'")
	
	* Blank Row for space and titles
	estadd local blank=""
	
	* New column
	local col="`col' col`c'"
	local colpost="`colpost' & (`c')"
	local gender=proper("`g'")
	local gpost="`gpost' & `gender'"
	
	* Outcome
	outcome, y(`outcome')

	local c=`c'+1			
}
}


* Save Table
esttab `col' using Output/rd_first_stage_reduced.tex, ///
	stats(${rows} outcome samplesize ffirst polynomial kernel bw, 							///
		fmt( %010.0gc )																///
		label(																		///
		"\addlinespace[0.3cm] \underline{\textit{First stage}}" 					///
			"\addlinespace[0.1cm]\hspace{.25cm}Age jump: 65" 						///
			" " 																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Age jump: 26" 						///
			" " 																	///
		"\addlinespace[0.3cm] \underline{\textit{Reduced Form}}" 					///
			"\addlinespace[0.1cm]\hspace{.25cm}Age jump: 65" 						///
			" " 																	///
			"\addlinespace[0.1cm]\hspace{.25cm}Age jump: 26" 						///
			" " 																	///
		"\addlinespace[0.3cm] \midrule Outcome"										/// 
		"\addlinespace[0.1cm]Sample size"											/// 	
		"\addlinespace[0.1cm]First-stage F Statistics"								/// 
		"\addlinespace[0.1cm]Polynomial"											/// 
		"\addlinespace[0.1cm]Kernal"												/// 
		"\addlinespace[0.1cm]Bandwidth"												/// 	
			))																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines longtable	nolines nonum		///
	prehead(\begin{tabular}{l*{20}{x{1.6cm}}} \toprule) 										///
	posthead(`colpost' \\  `gpost' \\\midrule)  ///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA