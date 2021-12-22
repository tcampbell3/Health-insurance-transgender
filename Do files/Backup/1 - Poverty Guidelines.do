
import excel "Data\Poverty Guidelines\Poverty Guidelines.xlsx", sheet("Sheet1") firstrow clear
save "DTA\poverty guidlines.dta", replace
