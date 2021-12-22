
* Rename variables, if policy changes mid year, choose latest
cap program drop clean
program clean

	* drop unneeded variables
	drop footnotes
	
	* rename state
	rename location stname

	* rename month
	forvalues y=2000/2020{
	foreach m in january february march april may june july august september october november december{
		cap confirm variable `m'`y'
		if _rc==0{
			cap rename `m'`y' medicaid_FPL`y'
			if _rc!=0{
				drop medicaid_FPL`y'
				rename `m'`y' medicaid_FPL`y'
			}
		}
	} 
	}
end

* Other adults
import delimited "Data\Medicaid Policies\Medicaid Income Eligibility Limits for Other Non-Disabled Adults, 2011-2020", varnames(3) encoding(UTF-8) rowrange(5:55) clear 

* Clean up
clean
reshape long medicaid_FPL, i(stname) j(year)

* States with basic health programs that extend medicaid-type benefits to 200% FPL
replace medicaid_FPL = 2 if inlist(stname, "Minnesota") | (inlist(stname,"New York")&year>2014)	

* Save
gsort stname year
compress
replace medicaid_FPL= round(medicaid_FPL*100) // no decimales due to stata precision issue
replace medicaid_FPL = . if inlist(medicaid_FPL,0)
save DTA/Medicaid_FPL,replace