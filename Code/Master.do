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

* Medicaid
do "Do Files/1 - Medicaid Thresholds.do"

* CPS (Modified Adjusted Gross Income by state-year-married-age-income)
do "Do Files/1 - March CPS.do"

* ACA Subsidy Schedule
do "Do Files/1 - ACA Subsidy Thresholds.do"

* Federal poverty level imputation
do "Do Files/1 - Merge Datasets Hot Deck"

******   2) Final Datasets    ******

* Stacked Dataset
global kernel="tri"
do "Do Files/2 - Stacked Dataset.do"

global kernel="uni"
do "Do Files/2 - Stacked Dataset.do"

global kernel="epa"
do "Do Files/2 - Stacked Dataset.do"


******   3) Results    ******

* Program RDD Estimates
do "Do Files/3 - RDD Programs.do"

* Map of BRFSS waves
do "Do Files/3 - Map.do"

* Descriptive Statistics
global title="\normalsize{Descriptive Statistics by Transgender Status}"
global footnote="Sample weights are applied. Percentages are rounded to closest integer. Sample omits states that do not use the sexual orientation gender identity module. We also omit any respondents who do not report their gender identity, household income, age, race, employment, education, or marital status--approximately 2.5\% of the sample. Federal poverty level is the ratio of a tax-units (group filing taxes together) total modified-adjusted gross income to size of the tax-unit. Since this information is not available on the BRFSS, we impute the federal poverty level using the 2015-2019 March CPS."
do "Do Files/3 - Descriptive Statistics.do"

* Binscatters
global kernel = "tri"
do "Do Files/3 - Binscatters.do"

* ACA subsidy estimates
do "Do Files/3 - Figure ACA Subsidy Thresholds.do"

* FPL Imputation Histograms
do "Do Files/3 - FPL Histograms.do"

* Figure of benchmark estimates by Kernel
foreach k in tri uni epa{
	global kernel = "`k'"
	global controls = "c._x*"
	global absorb = "rd#fips#year"
	global age="yes"
	do "Do Files/3 - Figure Benchmark Estimates.do"
}

* Poisson regression
global kernel="tri"
global age="yes"
do "Do Files/3 - Figure Poisson Estimates.do"

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
