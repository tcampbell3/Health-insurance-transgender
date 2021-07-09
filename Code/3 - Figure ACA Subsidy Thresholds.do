cd "${path}"
use DTA/Final, clear

keep if fpl >= 100 & fpl < 400

* Regressions
reg cap fpl [aw=_llcpwt] if fpl >= 100 & fpl < 133
local _b0_133 = _b[_cons]
local _b1_133 = _b[fpl]

reg cap fpl [aw=_llcpwt] if fpl >= 133 & fpl < 300
local _b0_300 = _b[_cons]
local _b1_300 = _b[fpl]

reg cap fpl [aw=_llcpwt] if fpl >= 300 & fpl < 400
local _b0_400 = _b[_cons]
local _b1_400 = _b[fpl]


g bins=floor((fpl-133)/14)
collapse cap fpl [aw=_llcpwt], by(bins)

twoway (function y=`_b0_133'+x*`_b1_133', range(100 133) col(midblue%90) lcolor(midblue%90) lw(medthick) lp(solid)) ///
	(function y=`_b0_300'+x*`_b1_300', range(133 300) col(midblue%90) lcolor(midblue%90) lw(medthick) lp(solid)) ///
	(function y=`_b0_400'+x*`_b1_400', range(300 400) col(midblue%90) lcolor(midblue%90) lw(medthick) lp(solid)) ///
	(scatter cap fpl, col(black%70) ms(O) msize(small)) ///
	, scheme(plotplain) xtitle("Federal poverty level",size(12pt)) ytitle("Insurance premium cap (% income)",size(12pt)) xlabel(100(50)400 133,labs(11pt))	///
	ylabel(0(1)10,labs(11pt))	xline(133, lp(dash) lcolor(red%90)) xline(300, lp(dash) lcolor(red%90)) legend(off)

* Save
graph export "Output/cap.pdf", replace		


