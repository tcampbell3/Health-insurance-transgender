* Set up
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
forvalues z = 1/5{
	
	* Row Counter
	global r=1
	global rows="" // blank row for "Mean . (SD)" label
	
	* Store Estimates
	est restore dummy
	eststo col`c'
	
	
	* Controls
	if `z'==1{
		local controls=""
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local race = " "
		estadd local marital = " "
		estadd local emp = " "
		estadd local fpl_cps = " "
		estadd local fpl_brfss = " "
	}
	if `z'==2{
		local controls="`controls' i.cellphone i.race"
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local race = "\checkmark"
		estadd local marital = " "
		estadd local emp = " "
		estadd local fpl_cps = " "
		estadd local fpl_brfss = " "
	}
	if `z'==3{
		local controls="`controls' i.marital#i.lgb i.children i.adult i.pregnant i.employ#i.educ"
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local race = "\checkmark"
		estadd local marital = "\checkmark"
		estadd local emp = "\checkmark"
		estadd local fpl_cps = " "
		estadd local fpl_brfss = " "
	}
	if `z'==4{
		local controls="`controls' i.fpl_bins"
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local race = "\checkmark"
		estadd local marital = "\checkmark"
		estadd local emp = "\checkmark"
		estadd local fpl_cps = "\checkmark"
		estadd local fpl_brfss = " "
	}		
	if `z'==5{
		local controls="i.fpl_bins_brfss i.cellphone i.race i.marital#i.lgb i.children i.adult i.pregnant i.employ#i.educ"
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local race = "\checkmark"
		estadd local marital = "\checkmark"
		estadd local emp = "\checkmark"
		estadd local fpl_cps = " "
		estadd local fpl_brfss = "\checkmark"
	}
	
	* Loop over outcome rows
	foreach outcome in  mental physical poor badhealth cost concentration errands depressed{
		use DTA/Stacked_`g'_`outcome'_${kernel}, clear
		drop if inlist(year,2020) & inlist(rd,2)								// Remove due to covid
		global rows="$rows blank"
		RDD_stack `outcome' insurance (`controls')#i.rd   [aw=_weight] if `g'==1 ,	///
			p(1) cluster(_psu_rd) a(i.fips#i.year#i.rd)
		_store_stacked , out(`outcome') c(`c')	
	}	
	
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
esttab `col' using Output/rd_stacked_controls.tex,				 				///
	stats(${rows} fe age race marital emp fpl_cps fpl_brfss, 						///
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
		"\addlinespace[0.3cm] \underline{\textit{Couldn't see doctor due to cost}}" 		///
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
		"\addlinespace[0.3cm] \midrule Controls: state-year fixed effects"		/// 		
		"\addlinespace[0.1cm]Controls: survey type and age"						/// 		
		"\addlinespace[0.1cm]Controls: race"									/// 
		"\addlinespace[0.1cm]Controls: family composition"						/// 	
		"\addlinespace[0.1cm]Controls: employment-education interaction"		/// 			
		"\addlinespace[0.1cm]Controls: federal poverty level (CPS)"				/// 
		"\addlinespace[0.1cm]Controls: federal poverty level (BRFSS)"			/// 		
		))																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines	nolines nonum	///
	prehead(\begin{tabular}{l*{20}{x{1.7cm}}} \toprule) 						///
	posthead(`colpost' \\  `gpost' \\\midrule)  								///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA