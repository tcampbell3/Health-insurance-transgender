cd "${path}"
import excel "Data\ACA Subsidy Thresholds\ACA Subsidy Schedule.xlsx", sheet("Sheet1") firstrow clear case(lower)
save DTA/ACA_Subsidy_Schedule, replace