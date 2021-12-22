

***************************************
***************************************
*********          			***********
*********	  Pool BRFSS   	***********
*********          			***********
***************************************
***************************************
	
cd "${path}\Data\BRFSS"
forvalues year=2014/2019{
	unzipfile "LLCP`year'XPT", replace
}
	
* IOWA 2015 uses optional SOGI question in version 1
unzipfile "LLCP15V1_XPT", replace
import sasxport5 "LLCP15V1.xpt", clear
gen year=2015
destring seqno, replace
keep if _state==19
rename _lcpwtv1 _llcpwt
save "..\..\DTA\BRFSS_IA_2015.dta", replace	

* Arizona 2018 uses optional SOGI question in version 2
unzipfile "LLCP18V2_XPT", replace
import sasxport5 "LLCP18V2.xpt", clear
gen year=2018
destring seqno, replace
keep if _state==4
rename _lcpwtv2 _llcpwt
save "..\..\DTA\BRFSS_AZ_2018.dta", replace	

* Import data
cd "${path}"
forvalues year =2014/2019{
	import sasxport5 "Data\BRFSS\LLCP`year'.xpt", clear
	gen year=`year'
	destring seqno, replace
	save "DTA\BRFSS_`year'.dta", replace
}

* Append Data
use "DTA\BRFSS_2014.dta", replace
forvalues year =2015/2019{
	append using "DTA\BRFSS_`year'.dta", 
}

* Append Iowa 2015
drop if year==2015 & _state==19
append using "DTA\BRFSS_IA_2015.dta"

* Append Arizona 2018
drop if year==2018 & _state==4
append using "DTA\BRFSS_AZ_2018.dta"

* ID
gen ID=_n

* Delete Unused Data
sleep 10000
forvalues year=2014/2019{
	erase "DTA\BRFSS_`year'.dta"
	erase "Data\BRFSS\LLCP`year'.XPT"
}
erase "DTA\BRFSS_IA_2015.dta"
erase "DTA\BRFSS_AZ_2018.dta"






***************************************
***************************************
*********          			***********
*********	  Clean up   	***********
*********          			***********
***************************************
***************************************

* Delete missing income or transgender data
drop if income2>8|income2==.|trns>4|trns==.

* Local variables to keep
local keep = "year _ageg5yr veteran income2 _llcpwt _psu"
sum `keep'

* State (need to impute with cps)
rename _state fips
drop if inlist(fips,.)
local keep = "`keep' fips"

* Control: Age (need to impute with cps)
rename _age80 age
drop if inlist(age,.,80)		// dropping topcoded age bracket of 80
local keep = "`keep' age"

* Household Children (need to impute with cps)
replace children = 0 if children == 88	// zero
replace children = . if children == 99	// missing
replace children = 10 if children>10	// topcoded
drop if inlist(children,.)
local keep = "`keep' children"

* Household Adults (need to impute with cps)
g adults = hhadult if hhadult < 77				// number adults on cellphone survey, >77 is refused/dont know
replace adults = numadult if  adults == .		// number adults on landling, missing is blank
replace adults = 1 if cclghous==1 | colghous==1 // adjust for college housing
replace adults = 10 if adults>10 & adults!=.	// topcoded
replace adults = 1 if adults==0					// 1 obs has error
drop if inlist(adults,.)
local keep = "`keep' adults"

* Control: Marital status (need to impute with cps)
replace marital = . if marital == 9 // 9 = missing
drop if inlist(marital,.)
local keep = "`keep' marital"

* Control: Education (need to impute with cps)
rename _educag education
drop if inlist(education,.,9)
local keep = "`keep' education"

* Control: Race (need to impute with cps)
rename _racegr3 race
replace race=3 if race==4 // combine other and mix
drop if inlist(race,.,9)
local keep = "`keep' race"

* Control: Employment (need to impute with cps)
replace employ1=9 if employ1==.  // 9 = missing
drop if inlist(employ1,.,9)
local keep = "`keep' employ1"

* Parent
g parent=(children>0)
local keep = "`keep' parent"

* Control: Sex
replace sex = sex1 if inlist(sex,.)	// sex question changes in 2018, elicited not percervied
replace sex = sexvar if inlist(sex,.)	// sex question changes in 2018, elicited not percervied
replace sex = . if sex>2			// code refused or don't know to missing
local keep = "`keep' sex"

* Transgender
g trans=inlist(trnsgndr,1,2,3)
g m2f=inlist(trnsgndr,1)
g f2m=inlist(trnsgndr,2)
g non=inlist(trnsgndr,3)
g cis=(trans==0)
g ciswomen=(cis==1&sex==2)
g cismen=(cis==1&sex==1)
drop if inlist(non,1)															// Only binary transgender sample
local keep = "`keep' trans m2f f2m cis ciswomen cismen"

* Control: Sexual orientation (gay, lesbian, bisexual, "something else", "other")
g lgb = inlist(sxorient,2,3,4) | inlist(somale,1,3,4) | inlist(sofemale,1,3,4)
replace lgb=9 if sxorient>4 & year<2018| year>=2018 & somale>4 & sex1==1 | year>=2018 & sofemale>4 & sex1==2
replace lgb=9 if sxorient==. & year<2018| year>=2018 & somale==. & sex1==1 | year>=2018 & sofemale==. & sex1==2
local keep = "`keep' lgb"

* Control: Pregnant
replace pregnant=(pregnant==1)
local keep = "`keep' pregnant"

* Control: CellPhone
gen cellphone=(qstver>=20)
replace cellphone=. if qstver==.
local keep = "`keep' cellphone"

* Control: Couple status
g couple=(marital==1|marital==6)
replace couple=. if marital==9|marital==.
local keep = "`keep' couple"

* Control: college
g college=(education==4)
replace college=. if education==9|education==.
local keep = "`keep' college"

* Control: White
g white=(race==1)
replace white=. if race==9
local keep = "`keep' white"

* Control: Smoking (currently)
g smoke = smokday2
replace smoke=3 if smoke100==2
replace smoke=9 if smoke100==9|smoke100==7|smoke==7|smoke==.  // 9 = missing
local keep = "`keep' smoke"

* Control: Drinking (per week)
g drink = alcday5
replace drink =0 if alcday5 ==888
replace drink =. if alcday5 ==777 | alcday5==999
replace drink = alcday5-100 if alcday5>100 & alcday5<200
replace drink = (alcday5-200)/30*7 if alcday5>200 & alcday5<300
local keep = "`keep' drink"

* Control: Binge Drinking (per week)
g binge = drnk3ge5/30*7
replace bing=0 if drink==0 | drnk3ge5==88
replace bing=. if drnk3ge5==77 | drnk3ge5==99
local keep = "`keep' binge"

* Control: BMI (underweight, normal weight, overweight, obese)
g bmi = _bmi5cat
replace bmi = 9 if bmi==. // 9 = missing
local keep = "`keep' bmi"

* Outcome:  mental health  intensive
g mental = menthlth
replace mental=0 if menthlth==88
replace mental=. if menthlth==77|menthlth==99
local keep = "`keep' mental"

* Outcome:  mental health extensive
g mental_ext = mental > 0 if !inlist(mental,.)
local keep = "`keep' mental_ext"

* Outcome:  pyhsical health
g physical = physhlth
replace physical=0 if physhlth==88
replace physical=. if physhlth==77|physhlth==99
local keep = "`keep' physical"

* Outcome: poorhlth
g poorhealth = poorhlth
replace poorhealth=0 if poorhlth==88 | physhlth==88 & menthlth==88
replace poorhealth=. if poorhlth==77|poorhlth==99|mental==.|physical==.
local keep = "`keep' poorhealth"

* Outcome: Difficult concentrating
replace decide = 9 if inlist(decide,7,9,.)
g concentration = (decide==1) if decide!=9 & decide!=.
local keep = "`keep' decide concentration"

* Outcome: Difficult errands
replace diffalon = 9 if inlist(diffalon,7,9,.)
g errands = (diffalon==1) if diffalon!=9 & diffalon!=.
local keep = "`keep' diffalon errands"

* Outcome: Depressive disorder
replace addepev2 = addepev3 if inlist(addepev2,.)
replace addepev2 = 9 if inlist(addepev2,7,9,.)
g depressed = (addepev2==1) if addepev2!=9 & addepev2!=.
local keep = "`keep' addepev2 depressed"

* Outcome: general health
replace genhlth = 9 if inlist(genhlth,7,9,.)
g goodhealth=inlist(genhlth,1,2,3)
replace goodhealth =. if genhlth==9
g badhealth=inlist(genhlth,5)
replace badhealth =. if genhlth==9
local keep = "`keep' genhlth goodhealth badhealth"

* Outomce: cannot see doctor due to cost
g cost=(medcost==1)
replace cost=. if inlist(medcost,7,9)
local keep = "`keep' medcost cost"

* Outcome: time since last check-up
local keep = "`keep' checkup1"

* Outcome: percived incongruence
g incongruence = (sex==1&m2f==1|sex==2&f2m==1)
replace incongruence = . if m2f!=1&f2m!=1|year>=2018|sex==.
local keep = "`keep' incongruence"

* Outcome: HIV test
g hivtest=(hivtst6==1)
replace hivtest=. if hivtst6==7|hivtst6==9
local keep = "`keep' hivtest"

* Outcome: Years since HIV test
replace hivtstd3=771985 if hivtstd3==771885 // fix typo
replace hivtstd3=72005 if hivtstd3==77005 // fix typo
replace hivtstd3= 52014  if hivtstd3== 51014  // fix typo
g hiv_years = year-(hivtstd3-int(hivtstd3/10000)*10000)
replace hiv_years=. if hiv_years<-1	// remove missing
replace hiv_years=0 if hiv_years==-1
local keep = "`keep' hiv_years"

* Treatment: insurance
g insurance=hlthpln1==1
replace insurance=. if hlthpln1>2|hlthpln1==.
local keep = "`keep' insurance"

* Keep variables of interest
keep `keep'
mdesc *
compress
order fips year _psu _llcpwt age 
sort  fips year age
save "DTA\BRFSS_Pooled.dta", replace
clear
