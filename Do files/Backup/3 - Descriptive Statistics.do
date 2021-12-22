

* Program descriptive statistics
cap program drop sumstat
program sumstat, rclass
	syntax varlist, type(string) group(varlist) [round(real 1.0)]
	tokenize `varlist'
	
	* Check if category is correctly specified
	cap assert "`type'"=="Categorical"|"`type'"=="Continious"
	if _rc!=0{
		di in red "ERROR: type must be either 'Categorical' or 'Continious'"
	}
	
	* Categorical Sum Stat
	if "`type'"=="Categorical"{
	
		* save blank rows for tital
		global rows="$rows blank"
		
		* number of categories
		tab `1'
		local c = r(r) 
		
		* population total of each category for group
		cap drop dummy
		g dummy = _llcpwt * `group'
		tabstat dummy, by(`1') stat(sum) save
		
		* loop over categories
		forvalues i=1/`c'{
			cap estadd scalar row$r =int(round(r(Stat`i')[1,1]/r(StatTotal)[1,1]*100))
			global rows="$rows row$r"
			global r = $r + 1
		}	
		drop dummy
		
	}
	
	* Continious Sum Stat
	if "`type'"=="Continious"{
		
		* Save one blank row for space between variables
		global rows="$rows"
		
		* Mean
		sum `1' [aw=_llcpwt] if `group'==1
		estadd scalar row$r = int(round(r(mean),`round')*(1/`round'))*`round'
		global rows="$rows row$r"
		global r = $r + 1
		
		* Standard Deviaion in paraenthsis
		local sd: di int(round(r(sd),`round')*(1/`round'))*`round'
		estadd local row$r = "(`sd')"
		global rows="$rows row$r"
		global r = $r + 1
		
	}
	end

***************************************
***************** Table ***************
***************************************

* Open Data
use DTA/Final, clear
replace medcost=9 if medcost==7
eststo clear
quietly reg _llcpwt
eststo dummy

* Groups
g all=1

* Column Counter
local c=1

* Loop Columns
foreach col in all cis trans {

	est restore dummy
	eststo col`c'
	
	* Row Counter
	global r=1
	
	********* Continious *********
	
	global rows="blank" // blank row for "Mean . (SD)" label

	* Mental  Health	
	sumstat mental, type(Continious) group(`col') round(.01) 
	
	* Physical Health	
	sumstat physical, type(Continious) group(`col') round(.01) 
	
	* Poor Health	
	sumstat poorhealth, type(Continious) group(`col') round(.01) 
	
	* Insurance	
	sumstat insurance, type(Continious) group(`col') round(.01) 

	* FPL
	sumstat fpl, type(Continious) group(`col') round(1) 

	* Age
	sumstat age, type(Continious) group(`col') round(.01) 
	
	* Binge
	sumstat binge, type(Continious) group(`col') round(.01) 

	* Drink
	sumstat drink, type(Continious) group(`col') round(.01) 
	
	* Survey
	sumstat cellphone, type(Continious) group(`col') round(.01) 
	
	********* Categorical *********
	
	global rows="${rows} blank"	// blank row for "Percentages:" label
	
	* General Health
	sumstat genhlth, type(Categorical) group(`col') round(.01) 
	
	* General Health
	sumstat medcost, type(Categorical) group(`col') round(.01) 

	* Concentrating
	sumstat decide, type(Categorical) group(`col') round(.01) 

	* Errands
	sumstat diffalon, type(Categorical) group(`col') round(.01) 
	
	* Depression
	sumstat addepev2, type(Categorical) group(`col') round(.01) 
	
	* BMI
	sumstat bmi, type(Categorical) group(`col') round(.01) 
	
	* Smoke
	sumstat smoke, type(Categorical) group(`col') round(.01) 
	
	* Employment	
	sumstat employ1, type(Categorical) group(`col') round(.01) 
	
	* Education
	sumstat educa, type(Categorical) group(`col') round(.01) 
		
	* Race
	sumstat race, type(Categorical) group(`col') round(.01) 

	* Marital Status
	sumstat marital, type(Categorical) group(`col') round(.01) 

	* Sexual Orientation
	sumstat lgb, type(Categorical) group(`col') round(.01) 
	
	* N
	cap drop N
	egen N = total(`col')
	sum N, meanonly
	estadd scalar row$r = round(r(mean))	
	global rows="$rows row$r"
	global r = $r + 1

	* Population
	cap drop population
	egen population = total(_llcpwt) if `col' == 1
	replace population = population/100000
	sum population, meanonly
	estadd scalar row$r = round(r(mean),.1)
	global rows="$rows row$r"
	global r = $r + 1
	
	* Years
	qui sum year
	local y1=r(min)
	local y2=r(max)-2000
	estadd local row$r = "`y1'-`y2'"
	global rows="$rows row$r"
	global r = $r + 1
	
	* Blank Row for space and titles
	estadd local blank=""
	
	* New column
	local c=`c'+1			
}



* Save Table
esttab col1 col2 col3 using "Output/Descriptive_statistics.tex",				///
	stats(${rows}, 																///
		fmt( %010.0gc )															///
		label("\addlinespace[0.3cm] \underline{\textit{Mean / (Standard Deviation):}}"	///
			"\addlinespace[0.3cm] Bad mental health days (over past 30)" 		///
			" " 																///
			"\addlinespace[0.3cm] Bad physical health days (over past 30)" 		///
			" " 																///
			"\addlinespace[0.3cm] Bad health days (over past 30)" 				///
			" " 																///
			"\addlinespace[0.3cm] Insurance coverage (1 = covered, 0 = uncovered)" 		///
			" " 																///
			"\addlinespace[0.3cm] Federal poverty level (income / poverty line \$* 100\$)" 	///
			" " 																///
			"\addlinespace[0.3cm] Age (18 - 80+)" 											///
			" " 																///
			"\addlinespace[0.3cm] Binge drinking (days per week)" 				///
			" " 																///
			"\addlinespace[0.3cm] Drinking (days per week)" 					///
			" " 																///				
			"\addlinespace[0.3cm] Cellphone survey (1 = cellphone, 0 = landline)" 	///
			" " 																///
			"\addlinespace[0.3cm] \underline{\textit{Percentages:}}"			///
			"\addlinespace[0.3cm] Self-reported health"		 					///
			"\hspace{.25cm}Excellent" 											///
			"\hspace{.25cm}Very good"											/// 
			"\hspace{.25cm}Good" 												///
			"\hspace{.25cm}Fair"												///
			"\hspace{.25cm}Poor"												///
			"\hspace{.25cm}Missing/refused"										///
			"\addlinespace[0.3cm] Couldn't see doctor due to cost"		 		///
			"\hspace{.25cm}Yes" 												///
			"\hspace{.25cm}No"													/// 
			"\hspace{.25cm}Missing/refused"										///
			"\addlinespace[0.3cm] Difficulty concentrating"		 				///
			"\hspace{.25cm}Yes" 												///
			"\hspace{.25cm}No"													/// 
			"\hspace{.25cm}Missing/refused"										///
			"\addlinespace[0.3cm] Difficulty doing errands"		 				///
			"\hspace{.25cm}Yes" 												///
			"\hspace{.25cm}No"													/// 
			"\hspace{.25cm}Missing/refused"										///
			"\addlinespace[0.3cm] Depressive disorder"			 				///
			"\hspace{.25cm}Yes" 												///
			"\hspace{.25cm}No"													/// 
			"\hspace{.25cm}Missing/refused"										///
			"\addlinespace[0.3cm] Body-mass-index group" 						///
			"\hspace{.25cm}Underweight" 										///
			"\hspace{.25cm}Normal weight"										/// 
			"\hspace{.25cm}Overweight" 											///
			"\hspace{.25cm}Obese"												///
			"\hspace{.25cm}Missing/refused"										///
			"\addlinespace[0.3cm] Current smoking status" 						///
			"\hspace{.25cm}Every day" 											///
			"\hspace{.25cm}Some days"											/// 
			"\hspace{.25cm}Not at all"											/// 
			"\hspace{.25cm}Missing/refused"										///
			"\addlinespace[0.3cm] Employment" 									///
			"\hspace{.25cm}Employed for wages" 									///
			"\hspace{.25cm}Self-employed"										/// 
			"\hspace{.25cm}Out of work for 1 year or more"						/// 
			"\hspace{.25cm}Out of work for less than 1 year"					///
			"\hspace{.25cm}A homemaker"											///
			"\hspace{.25cm}A student"											///
			"\hspace{.25cm}Retired"												///
			"\hspace{.25cm}Unable to work"										///
			"\addlinespace[0.3cm] Education" 									///
			"\hspace{.25cm}Did not graduate high school" 						///
			"\hspace{.25cm}Graduated high school"								/// 
			"\hspace{.25cm}Attended college"									/// 
			"\hspace{.25cm}Graduated from college"								///
			"\addlinespace[0.3cm] Race" 										///
			"\hspace{.25cm}White only, Non-Hispanic" 							///
			"\hspace{.25cm}Black only, Non-Hispanic"							/// 
			"\hspace{.25cm}Other, Non-Hispanic"									/// 
			"\hspace{.25cm}Hispanic"											///
			"\addlinespace[0.3cm] Marital Status" 								///
			"\hspace{.25cm}Married" 											///
			"\hspace{.25cm}Divorced"											/// 
			"\hspace{.25cm}Widowed"												/// 
			"\hspace{.25cm}Separated"											///
			"\hspace{.25cm}Never married"										///
			"\hspace{.25cm}Umarried couple"										///
			"\addlinespace[0.3cm] Sexual Orientation" 							///
			"\hspace{.25cm}Straight" 											///
			"\hspace{.25cm}Lesbian, gay, or bisexual"							/// 
			"\hspace{.25cm}Missing/refused"										/// 
			"\addlinespace[0.3cm] \midrule Sample size" 						///
			"Weighted sample size (100,000s)" 									///
			"Years" 															///
			))																	///
	keep( ) replace nomtitles nonotes booktabs nogap nolines longtable	nolines nonum		///
	prehead(\begin{longtable}{l*{50}{c}} ///
		\caption{${title}\label{tab:sumstat}} ///
		\endfirsthead ///
		\caption[]{${title}} \\ ///
		\toprule ///
		&(1)  &(2)  &(3)        \\ ///
		& All & Cis & Trans     \\ ///
		\midrule ///
		\endhead ///
		\bottomrule ///
		\endfoot ///
		\caption*{\footnotesize{\textit{Notes:} "${footnote}"}} ///
		\endlastfoot ///
		\toprule ///
	) 						///
	posthead(&(1)  &(2)  &(3)  \\  & All & Cis & Trans \\\midrule)  ///
	postfoot("\bottomrule" "\end{longtable}") 

