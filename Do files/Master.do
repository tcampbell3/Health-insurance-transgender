* Setup
clear all
global path "C:\Users\travi\Dropbox\Transgender Healthcare"
cd "${path}"

******   1) Individual Datasets    ******

* Stack BRFSS, Define Sample
do "Do Files/1 - BRFSS.do"

* State FIPS codes
do "Do Files/1 - State FIPS.do"

* Poverty Guidelines
do "Do Files/1 - Poverty Guidelines.do"

* Povert threshold (alternative measure)
do "Do Files/1 - Poverty thresholds.do"

* CPS (Modified Adjusted Gross Income by state-year-married-age-income)
do "Do Files/1 - March CPS.do"

* Federal poverty level
do "Do Files/1 - Merge Datasets Hot Deck"

* Medicaid thresholds for expansion map
do "Do Files/1 - Medicaid Thresholds.do"

******   2) Final Datasets    ******

* Stacked Datasets
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Stacked Dataset.do" tri
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Stacked Dataset.do" uni
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Stacked Dataset.do" epa


******   3) Results    ******

* Program RDD Estimates
do "Do Files/3 - RDD Programs.do"

* Map of BRFSS waves
do "Do Files/3 - Map.do"
do "Do Files/3 - Map medicaid.do"

* Descriptive Statistics
global title="\normalsize{Descriptive Statistics by Transgender Status, BRFSS 2015-2020}"
global footnote="Sample weights are applied. Percentages are rounded to closest integer. Sample omits states that do not use the sexual orientation gender identity module. We also omit any respondents who do not report their gender identity, household income, age, race, employment, education, or marital status--approximately 2.5\% of the sample. Federal poverty level is the ratio of a tax-units (group filing taxes together) total modified-adjusted gross income to size of the tax-unit. Since this information is not available on the BRFSS, we impute the federal poverty level using the 2015-2021 March CPS."
do "Do Files/3 - Descriptive Statistics.do"

* Binscatters
global kernel = "tri"
do "Do Files/3 - Binscatters.do"

* FPL Imputation Histograms
do "Do Files/3 - FPL Histograms.do"

* Figure of benchmark estimates by Kernel
foreach k in tri uni epa{
	global kernel = "`k'"
	global controls = "i.cellphone i.fpl_bins i.race i.marital#i.lgb i.children i.adult i.pregnant i.employ#i.educ"
	global absorb = "rd#fips#year"
	global BRFSS_2020 = ""
	do "Do Files/3 - Figure Benchmark Estimates.do"
}

* Robustness test - 2020 data
global kernel = "tri"
global controls = "i.cellphone i.fpl_bins i.race i.marital#i.lgb i.children i.adult i.pregnant i.employ#i.educ"
global absorb = "rd#fips#year"
global BRFSS_2020="no"																// drop all of 2020
do "Do Files/3 - Figure Benchmark Estimates.do"
global BRFSS_2020="yes"																// include all of 2020
do "Do Files/3 - Figure Benchmark Estimates.do"

* RD plots	- Insurance
global y = "insurance"
global title1= "Insurance coverage rate"
global title2=""
do "Do Files/3 - RD plots.do"
do "Do Files/3 - RD plots.do" restricted

* RD plots	- College
global y = "college"
global title1= "College educational attainment rate"
global title2=""
do "Do Files/3 - RD plots.do"
do "Do Files/3 - RD plots.do" restricted

* RD plots	- Married
global y = "married"
global title1= "Marriage rate"
global title2=""
do "Do Files/3 - RD plots.do"
do "Do Files/3 - RD plots.do" restricted

* RD plots	- Employment
global y = "employed"
global title1= "Employment rate"
global title2=""
do "Do Files/3 - RD plots.do"
do "Do Files/3 - RD plots.do" restricted

* RD plots	- FPL
global y = "fpl"
global title1= "Federal Poverty Level (CPS)"
global title2=""
do "Do Files/3 - RD plots.do"
do "Do Files/3 - RD plots.do" restricted

* RD plots	- FPL BRFSS
global y = "fpl_brfss"
global title1= "Federal Poverty Level (BRFSS)"
global title2=""
do "Do Files/3 - RD plots.do"
do "Do Files/3 - RD plots.do" restricted

* RDD 1st stage by bandwidth and polynomial
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Table First Stage and Reduced Form.do"

* Stacked-RDD by polynomial
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Table RDD Stacked by Polynomial.do"

* Stacked-RDD by age
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Table RDD Stacked by Age.do"

* Stacked-RDD by bandwidth
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Table RDD Stacked by Bandwidth.do"

* Stacked-RDD by controls
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Table RDD Stacked by Controls.do"

* Predicting SOGI module
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Predicting missing data"