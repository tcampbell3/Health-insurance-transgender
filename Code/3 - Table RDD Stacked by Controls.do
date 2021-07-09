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
forvalues z = 1/6{
	
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
		estadd local age = " "
		estadd local edu = " "
		estadd local marital = " "
		estadd local emp = " "
		estadd local lasso = " "
	}
	if `z'==2{
		local controls="`controls' i.cellphone i.X"
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local edu = " "
		estadd local marital = " "
		estadd local emp = " "
		estadd local lasso = " "
	}
	if `z'==3{
		local controls="`controls' i.race"
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local edu = "\checkmark"
		estadd local marital = " "
		estadd local emp = " "
		estadd local lasso = " "
	}
	if `z'==4{
		local controls="`controls' i.marital#i.lgb i.children i.adult i.pregnant"
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local edu = "\checkmark"
		estadd local marital = "\checkmark"
		estadd local emp = " "
		estadd local lasso = " "
	}		
	if `z'==5{
		local controls="`controls' i.employ#i.educ"
		estadd local fe = "\checkmark"
		estadd local age = "\checkmark"
		estadd local edu = "\checkmark"
		estadd local marital = "\checkmark"
		estadd local emp = "\checkmark"
		estadd local lasso = " "
	}
	if `z'==6{
		local controls="c._x*"
		estadd local fe = "\checkmark"
		estadd local age = ""
		estadd local edu = ""
		estadd local marital = ""
		estadd local emp = ""
		estadd local lasso = "\checkmark"
	}
	
	* Loop over outcome rows
	foreach outcome in  mental physical poor badhealth cost concentration errands depressed{
		use DTA/Stacked_`g'_`outcome'_${kernel}, clear
		keep if inlist(rd,1,2)													// age dis. only
		forvalues i = 1/2{
			cap drop dummy
			xtile dummy=fpl [aw=_llcpwt],n(5)
			replace X=dummy if inlist(rd,`i')
		}
		forvalues i = 3/7{
			cap drop dummy
			xtile dummy=age [aw=_llcpwt],n(5)
			replace X=dummy if inlist(rd,`i')
		}
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
	stats(${rows} fe age edu marital emp lasso, 						///
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
		"\addlinespace[0.1cm]Controls: survey type, age and federal poverty level"			/// 		
		"\addlinespace[0.1cm]Controls: race"									/// 
		"\addlinespace[0.1cm]Controls: family composition"						/// 	
		"\addlinespace[0.1cm]Controls: employment-education interaction"		/// 			
		"\addlinespace[0.1cm]Controls: triple-post-lasso regularization"		/// 			
		))																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines	nolines nonum	///
	prehead(\begin{tabular}{l*{20}{x{1.7cm}}} \toprule) 						///
	posthead(`colpost' \\  `gpost' \\\midrule)  								///
	postfoot(\bottomrule \end{tabular}) 

* Exit stata
exit, clear STATA