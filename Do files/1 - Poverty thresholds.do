/****************************
hhpersons = adults + children
Assumes adults > children
****************************/

* Temporary frame and file
tempvar tframe
tempfile temp
frame create `tframe'

* Loop years
forvalues y=14/20{
	
	frame `tframe'{
	
		* Import thresholds
		if `y'==15{
			import excel "Data\Poverty thresholds\thresh`y'.xls", sheet("Sheet1") cellrange(A7:K24) firstrow clear
			rename ormore Eightormore
		}
		else{
			import excel "Data\Poverty thresholds\thresh`y'.xls", sheet("Sheet1") cellrange(A6:K24) firstrow clear
		}
		
		* Drop what isn't needed (empty and age 65 and older)
		g index=_n
		drop if inlist(index,1,2,3,4,6,7,8,10,11)

		* Household adults
		g hhpersons = _n

		* Rename number of children
		rename None povertyline0
		rename One povertyline1
		rename Two povertyline2
		rename Three povertyline3
		rename Four povertyline4
		rename Five povertyline5
		rename Six povertyline6
		rename Seven povertyline7
		rename Eightormore povertyline8

		* Reshape
		keep hhpersons povertyline*
		reshape long povertyline, i(hhpersons) j(children)
		drop if inlist(povertyline,.)
		
		* Year
		g year = 20`y'
		
		* Save
		save `temp', replace
	}
	
	* Stack
	if `y'==14{
		use `temp', clear
	}
	else{
		append using `temp'
	}

}

* Save
compress
save DTA/poverty_thresholds, replace