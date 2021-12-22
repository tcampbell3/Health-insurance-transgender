
*************************************
		// 1) Open CPS
*************************************

* Unzip CPS
cd "${path}\Data\March CPS"
forvalues year=2014/2020{
	unzipfile "asec`year'_pubuse", replace
}

* Create 2014 (redesigned) through 2018 dataset
forvalues year=2014/2018{
	clear
	do cpsmar`year'.do
}

* 2019+ data (csv)
forvalues year=2019/2020{
	
	local y = `year'-2000
	
	* household file		
	import delimited "hhpub`y'.csv", encoding(ISO-8859-2) clear 
	save household,replace

	* family file
	import delimited "ffpub`y'.csv", encoding(ISO-8859-2) clear
	save family,replace

	* Individual
	import delimited "pppub`y'.csv", encoding(ISO-8859-2) clear 
	
	* Merge Household data
	g h_seq=ph_seq
	merge m:1 h_seq  using household, nogen  keep(1 3)

	* Merge Family (see for merging description: https://www.shadac.org/sites/default/files/publications/UPDATED%209.1%20CPS%20technical%20Brief.pdf)
	g fh_seq=ph_seq
	g ffpos = pf_seq 
	merge m:1 fh_seq ffpos using family, nogen   keep(1 3)
	
	* Save
	tostring peridnum, replace force // required for append
	save cpsmar`year'.dta, replace
	
}

*  Append CPS
use "cpsmar2014", clear
forvalues year=2015/2020{
	append using "cpsmar`year'"
}
replace marsupwt = marsupwt/100 // "2 implied decimals (example: 255212=2552.12)"

* year
g year = h_year-1


*******************************************
  // 2) Merge Federal Poverty Thresholds
*******************************************

bys gestfips (gestcen): replace gestcen=gestcen[_n-1] if gestcen==.
decode gestcen, g(stname)
rename gestfips fips
g place = "Other"
replace place = "AK" if stname=="Alaska"
replace place = "HI" if stname=="Hawaii"
merge m:1 place year using "../../DTA\poverty guidlines.dta", nogen keep(3)


*************************************
  // 3) Federal Poverty Level
*************************************

* Creat a couple id index (spouse or cohabiting partner)
g couple_num= a_spouse
replace couple_num = pecohab if a_spouse==0 & pecohab>0
cap drop dummy*
bys year ph_seq pf_seq: gen dummy_first = min(couple_num, a_lineno)
bys year ph_seq pf_seq: gen dummy_second = max(couple_num, a_lineno)
egen couple_id=group(year ph_seq pf_se dummy_first dummy_second)
replace couple_id=. if couple_num < 1 | couple_num == .

* Match dependents to head of household
g dep_id = dep_stat
replace dep_id = a_lineno if dep_stat==0

* Create tax unit
cap drop dummy
bys couple_id: egen dummy=min(a_lineno) if couple_id!=. & inlist(filestat,1,2,3)
replace dummy = dep_id if dummy==.
egen tax_unit = group(year ph_seq pf_se dummy)

* Starting in 2019 tax unit is given in march cps
replace tax_unit = tax_id * 1000000 if !inlist(tax_id,.)
drop tax_id
gegen tax_id = group(tax_unit) 
drop tax_unit
order year tax_id a_lineno
sort year tax_id a_lineno

* Tax Unit Size
cap drop fpersons
bys tax_id year: egen fpersons =count(tax_id)

* Tax Unit Modiefied Adjusted Gross Income (See: http://laborcenter.berkeley.edu/pdf/2019/magi.pdf)
	
	* Adjusted Gross Income
	cap drop ftotval
	bys tax_id year: egen ftotval =total(agi)
	
	/* Add Back Security Income 
	replace ss_val = 0 if ss_val<0
	bys tax_id year: egen tot_ss_val =total(ss_val)
	replace ftotval = ftotval + tot_ss_val*/

* Poverty line
g poverty_line = baseline + increment*fpersons
	
* Poverty ratio
cap drop fpl
g fpl = ftotval / poverty_line * 100


*************************************
		// 4) Subsample
*************************************

* Drop those in armed forces
drop if inlist(hrhtype,02,05,08)


*************************************
		// 5) BRFSS Controls
*************************************

* Coarse BRFSS Income
g income2 = 1 if htotval < 10000
replace income2 = 2 if htotval >= 10000 & htotval < 15000
replace income2 = 3 if htotval >= 15000 & htotval < 20000
replace income2 = 4 if htotval >= 20000 & htotval < 25000
replace income2 = 5 if htotval >= 25000 & htotval < 35000
replace income2 = 6 if htotval >= 35000 & htotval < 50000
replace income2 = 7 if htotval >= 50000 & htotval < 75000
replace income2 = 8 if htotval >= 75000 

* Number of Children in household
cap drop dummy
g dummy=(a_age-1<18) // income is one year old
bys ph_seq year: egen children=total(dummy)
replace children = 10 if children>10	// topcoded

* Number of Adults in household
cap drop dummy
g dummy=(a_age-1>=18) // income is one year old
bys ph_seq year: egen adults=total(dummy)
replace adults = 10 if adults>10					// topcoded

* Race 
g race=1 if prdtrace==1 //white only
replace race=2 if prdtrace==2 //black only
replace race = 5 if spm_hhisp==1 // hispanic
replace race = 3 if race==. // Other/mixed

* Education
g education = 1 if a_hga<=38 			// lt high school
replace education = 2 if a_hga== 39 	// high school
replace education = 3 if a_hga==40 		// some college
replace education =4 if a_hga>40 		// graduated college or technical degree

* Marital MARITL
g marital = 1 if inlist(a_maritl,1,2,3)	// married
replace marital = 2 if a_maritl == 5	// divorced
replace marital = 3 if a_maritl == 4	// widowed
replace marital = 4 if a_maritl == 6	// separated
replace marital = 5 if a_maritl == 7	// never married
replace marital = 6 if pecohab > 0 		// unmarried couple

* Employment employ1
g employ1 = .
replace employ1 = 1 if inlist(ljcw,1,2,3,4)										// employed for wages
replace employ1 = 3 if inlist(rsnnotw,5,6)										// Out of work more than one year
replace employ1 = 4 if workyn==1 & (a_nlflj == 1 | inlist(pemlr,3,4,7)) 		// Out of work less than one year
replace employ1 = 5 if rsnnotw == 3												// A homemaker
replace employ1 = 6 if rsnnotw == 4												// A student
replace employ1 = 7 if rsnnotw == 2	| workyn==1 & pemlr== 5						// Retired
replace employ1 = 8 if rsnnotw == 1	| workyn==1 & pemlr== 6						// unable to work	
replace employ1 = 2 if inlist(ljcw,5,6) | inlist(a_clswkr,5,6) 					// self employed
tab employ1 [aw=marsup] if a_age>=18

*  Age
drop if a_age<18 						// BRFSS only includes data for ages>=18
rename a_age age

* Delete unused data
cap log close
forvalues year=2014/2019{
	cap erase "asec`year'_pubuse.dat"
	cap erase "cpsmar`year'.dta"
	cap erase "cpsmar`year'.log"
}
erase family.dta
erase household.dta
erase ffpub19.csv
erase hhpub19.csv
erase pppub19.csv

* Drop observations with missing values required for BRFSS match
dropmiss fpl marsupwt income2 year children adults race education marital employ1 age fips , obs any force
cd "${path}"

* Save insurance file for figures
merge m:1 fips using "DTA/state_fips", nogen keep(3)
merge m:1 stname year using DTA/Medicaid_FPL, nogen keep(1 3) 
save DTA/CPS_Insurance, replace

* Save CPS
keep tax_id fpl marsupwt income2  employ1 stname year children adults race education marital age fips
order tax_id fpl marsupwt income2 employ1 stname year children adults race education marital age fips
gsort tax_id 
save "DTA/March CPS", replace


/* CPS Employment codebook
PEMLR
Major labor force recode
1 271 (0:7)
Values: 0 = NIU
1 = Employed - at work
2 = Employed - absent
3 = Unemployed - on layoff
4 = Unemployed - looking
5 = Not in labor force - retired
6 = Not in labor force - disabled
7 = Not in labor force - other
Universe: All Persons

A_CLSWKR
Class of worker
1 243 (0:8)
Values: 0 = Not in universe or children and Armed Forces
1 = Private
2 = Federal government
3 = State government
4 = Local government
5 = Self-employed-incorporated
6 = Self-employed-not incorporated
7 = Without pay
8 = Never worked
Universe: PEMLR=1-3 or


A_NLFLJ
When did ... last work for pay at a regular job or business,
either full- time or part-time
1 251 (-1:7)
Values: 0 = Not in universe or children and Armed Forces
1 = Within a past 12 months
3 = More than 12 months ago
7 = Never worked
Universe: PEMLR=5,6,or 7

A_WKSLK
Duration of unemployment
3 264 (0:99)
Values: 000 = NIU, Children or Armed Forces
001-999 = Entry
Universe: PEMLR=3 or 4

RSNNOTW
What was the main reason ... did not work in 20..?
1 324 (0:6)
Values: 0 = niu
1 = ill or disabled
2 = retired
3 = taking care of home
4 = going to school
5 = could not find work
6 = other
Universe: WORKYN = 2


WORKYN
Did ... work at a job or business at any time during 20..?
1 340 (0:2)
Values: 0 = niu
1 = yes
2 = no
Universe: All Persons aged 15+


BRFSS Employment
. use DTA/Final, clear

. tab employ1 [aw=_llcpwt]

 EMPLOYMENT |
     STATUS |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 | 402,775.31       50.03       50.03
          2 | 74,424.934        9.24       59.27
          3 | 19,523.556        2.42       61.70
          4 | 21,268.734        2.64       64.34
          5 | 46,948.436        5.83       70.17
          6 | 37,633.592        4.67       74.84
          7 | 145,274.57       18.04       92.89
          8 | 53,476.769        6.64       99.53
          9 | 3,797.0961        0.47      100.00
------------+-----------------------------------
      Total |    805,123      100.00

