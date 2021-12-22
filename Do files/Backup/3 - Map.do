
* Open Data
use DTA/Final, clear

* Count years of data by state
keep stabb year
gduplicates drop
gcollapse (count) year, by(stabb)

* Create map
rename stabb state
maptile year, geo(state) cutvalues(1.1 2.1 3.1 4.1 5.1) ///
twopt(legend(lab(1 "Never asked") lab(2 "1 year") lab(3 "2 years") lab(4 "3 years") lab(5 "4 years") lab(6 "5 years") lab(7 "6 years")))

* Save Map
graph export Output/map.pdf, replace 