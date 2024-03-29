********************************************************************************
*
*	Do-file:		an_table1.do
*
*	Project:		SGTF-617 CFR
*
*	Programmed by:	Daniel Grint
*
*	Data used:		output/cr_analysis_dataset.dta
*
*	Data created:	
*
*	Other output:	Table 1 Study population
*
********************************************************************************
*
*	Purpose:		This do-file creates table 1
*  
********************************************************************************

* Open a log file
cap log close
log using ./logs/an_table1, replace t

clear


use ./output/cr_analysis_dataset.dta



********************************************************************************
*	PROGRAMS TO AUTOMATE TABULATIONS
*
********************************************************************************
* All below code from K Baskharan 
* Generic code to output one row of table

cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)
	
	sum `variable' if `variable' `condition'
	**K Wing additional code to aoutput variable category labels**
	local level=substr("`condition'",3,.)
	local lab: label `variable'Lab `level'
	file write tablecontent (" `lab'") _tab
	
	/*this is the overall column*/
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	/*this loops through groups*/
	forvalues i=0/1{
	cou if sgtf == `i'
	local rowdenom = r(N)
	cou if sgtf == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontent _n
end


* Output one row of table for co-morbidities and meds
* This puts it all on the same row, is rohini's edit

cap prog drop generaterow2 
program define generaterow2
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)5
	
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	forvalues i=0/1{
	cou if sgtf == `i'
	local rowdenom = r(N)
	cou if sgtf == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontent _n
end


********************************************************************************

/* Explanatory Notes 
defines a program (SAS macro/R function equivalent), generate row
the syntax row specifies two inputs for the program: 
	a VARNAME which is your variable 
	a CONDITION which is a string of some condition you impose 
	
the program counts if variable and condition and returns the counts
column percentages are then automatically generated
this is then written to the text file 'tablecontent' 
the number followed by space, brackets, formatted pct, end bracket and then tab
the format %3.1f specifies length of 3, followed by 1 dp. 
*/ 

********************************************************************************
* Generic code to output one section (varible) within table (calls above)

cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterow, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow, variable(`variable') condition("== 12")
	
end


********************************************************************************

/* Explanatory Notes 
defines program tabulate variable 
syntax is : 
	- a VARNAME which you stick in variable 
	- a numeric minimum 
	- a numeric maximum 
	- optional missing option, default value is . 
forvalues lowest to highest of the variable, manually set for each var
run the generate row program for the level of the variable 
if there is a missing specified, then run the generate row for missing vals
*/ 

********************************************************************************
* Generic code to qui summarize a continous variable 

cap prog drop summarizevariable 
prog define summarizevariable
syntax, variable(varname) 

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 


	qui summarize `variable', d
	file write tablecontent ("Mean (SD)") _tab 
	file write tablecontent  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	
	forvalues i=0/1{							
	qui summarize `variable' if sgtf == `i', d
	file write tablecontent  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	}

file write tablecontent _n

	
	qui summarize `variable', d
	file write tablecontent ("Median (IQR)") _tab 
	file write tablecontent %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	
	forvalues i=0/1{
	qui summarize `variable' if sgtf == `i', d
	file write tablecontent %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	}
	
file write tablecontent _n
	
end



********************************************************************************
* INVOKE PROGRAMS FOR TABLE 1 
*
********************************************************************************

* DROP MISSING UTLA
noi di "DROPPING MISSING UTLA DATA"
drop if utla_group==""

* DROP IF NO DATA ON SGTF
noi di "DROPPING NO SGTF DATA" 
drop if has_sgtf==0



*Set up output file
cap file close tablecontent

file open tablecontent using ./output/table1.txt, write text replace

file write tablecontent ("Table 1: Demographic and Clinical Characteristics") _n

file write tablecontent _tab ("Total")		_tab ///
							 ("B.1.617")	_tab ///
							 ("B.1.1.7")	_n
							 


* DEMOGRAPHICS (more than one level, potentially missing) 

/*reminder of variables:
patient_id age ageCat hh_id hh_size hh_composition case_date case eth5 eth16 ethnicity_16 indexdate sex bmicat smoke imd region comorb_Neuro comorb_Immunosuppression shielding chronic_respiratory_disease chronic_cardiac_disease diabetes chronic_liver_disease cancer egfr_cat hypertension smoke_nomiss rural_urban
*/

*N
label define cox_popLab 1 "N"
label values cox_pop cox_popLab
tabulatevariable, variable(cox_pop) min(1) max(1) 
file write tablecontent _n 

*AE ATTENDANCE
tabulatevariable, variable(end_ae_test) min(0) max(1) 
file write tablecontent _n

*DIED
tabulatevariable, variable(died) min(0) max(1) 
file write tablecontent _n

*DIED PRE-CENS
tabulatevariable, variable(died_pre_cens) min(0) max(1) 
file write tablecontent _n

*VACCINATED
tabulatevariable, variable(vacc) min(0) max(1) 
file write tablecontent _n

*PREVIOUS INFECTION
tabulatevariable, variable(prev_inf) min(0) max(1) 
file write tablecontent _n

*EPI WEEK
tabulatevariable, variable(start_week) min(1) max(12) 
file write tablecontent _n 

*SEX
tabulatevariable, variable(male) min(0) max(1) 
file write tablecontent _n 

*AGE
summarizevariable, variable(age) 
file write tablecontent _n

tabulatevariable, variable(agegroup) min(0) max(7) 
file write tablecontent _n 

*ETHNICITY
tabulatevariable, variable(eth5) min(1) max(6) 
file write tablecontent _n 

*BMI
tabulatevariable, variable(obese4cat) min(1) max(4) 
file write tablecontent _n 

*SMOKING
tabulatevariable, variable(smoke_nomiss) min(1) max(3) 
file write tablecontent _n

*COMORBIDITIES (3 CATEGORIES)
tabulatevariable, variable(comorb_cat) min(0) max(2) 
file write tablecontent _n

*IMD
tabulatevariable, variable(imd) min(1) max(5) 
file write tablecontent _n 

*HOUSEHOLD SIZE
replace hh_total_cat = 5 if hh_total_cat==.
label define hh_total_catLab 5 "Missing", modify
tabulatevariable, variable(hh_total_cat) min(1) max(5) 
file write tablecontent _n 

*CARE HOME
tabulatevariable, variable(home_bin) min(0) max(1) 
file write tablecontent _n 

*REGION
tabulatevariable, variable(region) min(0) max(8) 
file write tablecontent _n 

*RURAL URBAN (five categories)
replace rural_urban5 = 6 if rural_urban5==.
label define rural_urban5Lab 6 "Missing", modify
tabulatevariable, variable(rural_urban5) min(1) max(6) 
file write tablecontent _n 



file write tablecontent _n _n


file close tablecontent


*AGE BY EPI WEEK

/*
*ALPHA
tab agegroup start_week if sgtf==1, matcell(alpha)

matrix inv_alpha = alpha'
svmat inv_alpha

*CUMULATIVE
gen cum_alpha1= inv_alpha1

forvalues i= 2/8{
local j= `i'-1
gen cum_alpha`i'= cum_alpha`j' + inv_alpha`i'
}

*CONVERT TO %
forvalues i= 1/8{
gen perc_alpha`i'= (cum_alpha`i'/cum_alpha8)*100
}

gen age_plot = _n-1 in 1/8
label values age_plot agegroupLab

twoway (area perc_alpha8 perc_alpha7 perc_alpha6 perc_alpha5 perc_alpha4 perc_alpha3 perc_alpha2 perc_alpha1 age_plot, ///
		graphregion(color(white)) yla(0(10)100) xla(0 "07APR" 1 "15APR" 2 "22APR" 3 "28APR" 4 "06MAY" 5 "13MAY" 6 "20MAY" 7 "27MAY") ///
		ytitle("Proportion") xtitle("Study week") legend(off))

graph export ./output/alpha_ageband.svg, as(svg) replace


*DELTA
tab agegroup start_week if sgtf==0, matcell(delta)

matrix inv_delta = delta'
svmat inv_delta

*CUMULATIVE
gen cum_delta1= inv_delta1

forvalues i= 2/8{
local j= `i'-1
gen cum_delta`i'= cum_delta`j' + inv_delta`i'
}

*CONVERT TO %
forvalues i= 1/8{
gen perc_delta`i'= (cum_delta`i'/cum_delta8)*100
}

twoway (area perc_delta8 perc_delta7 perc_delta6 perc_delta5 perc_delta4 perc_delta3 perc_delta2 perc_delta1 age_plot, ///
		graphregion(color(white)) yla(0(10)100) xla(0 "07APR" 1 "15APR" 2 "22APR" 3 "28APR" 4 "06MAY" 5 "13MAY" 6 "20MAY" 7 "27MAY") ///
		ytitle("Proportion") xtitle("Study week") legend(off))
		
graph export ./output/delta_ageband.svg, as(svg) replace

*/

*CUMULATIVE CASES BY AGEGROUP
gen case = 1

sort sgtf agegroup study_start
bysort sgtf agegroup (study_start) : gen cum_case = sum(case)

*Delta
line cum_case study_start if sgtf==0 & agegroup == 0 || ///
	line cum_case study_start if sgtf==0 & agegroup == 1 || ///
	line cum_case study_start if sgtf==0 & agegroup == 2 || ///
	line cum_case study_start if sgtf==0 & agegroup == 3 || ///
	line cum_case study_start if sgtf==0 & agegroup == 4 || ///
	line cum_case study_start if sgtf==0 & agegroup == 5 || ///
	line cum_case study_start if sgtf==0 & agegroup == 6 || ///
	line cum_case study_start if sgtf==0 & agegroup == 7, ///
	legend(off)
	
/*
	legend(lab(1 "0-<18") lab(2 "18-<30") lab(3 "30-<40") lab(4 "40-<50") lab(5 "50-<60") ///
			lab(6 "60-<70") lab(7 "70-<80") lab(8 "80+"))
*/
			
graph export ./output/delta_cumcase.svg, as(svg) replace

	
*Alpha
line cum_case study_start if sgtf==1 & agegroup == 0 || ///
	line cum_case study_start if sgtf==1 & agegroup == 1 || ///
	line cum_case study_start if sgtf==1 & agegroup == 2 || ///
	line cum_case study_start if sgtf==1 & agegroup == 3 || ///
	line cum_case study_start if sgtf==1 & agegroup == 4 || ///
	line cum_case study_start if sgtf==1 & agegroup == 5 || ///
	line cum_case study_start if sgtf==1 & agegroup == 6 || ///
	line cum_case study_start if sgtf==1 & agegroup == 7, ///
	legend(off)
	
/*
	legend(lab(1 "0-<18") lab(2 "18-<30") lab(3 "30-<40") lab(4 "40-<50") lab(5 "50-<60") ///
			lab(6 "60-<70") lab(7 "70-<80") lab(8 "80+"))
*/

graph export ./output/alpha_cumcase.svg, as(svg) replace



*AE ATTENDANCE
histogram ae_admission_date, freq color(red%30)
graph export ./output/ae_hist.svg, as(svg) replace

twoway kdensity ae_admission_date if start_week==1 || ///
	kdensity ae_admission_date if start_week==2 || ///
	kdensity ae_admission_date if start_week==3 || ///
	kdensity ae_admission_date if start_week==4 || ///
	kdensity ae_admission_date if start_week==5 || ///
	kdensity ae_admission_date if start_week==6 || ///
	kdensity ae_admission_date if start_week==7 || ///
	kdensity ae_admission_date if start_week==8 || ///
	kdensity ae_admission_date if start_week==9 || ///
	kdensity ae_admission_date if start_week==10 || ///
	kdensity ae_admission_date if start_week==11 || ///
	kdensity ae_admission_date if start_week==12 ///
	, legend(off) xlabel(,format(%td))
	
	
tab vacc end_ae_test, row
bysort sgtf: tab vacc end_ae_test, row
	
tab ae_dest sgtf

	
graph export ./output/ae_kden.svg, as(svg) replace


* Close log file 
log close

clear

insheet using ./output/table1.txt, clear

export excel using ./output/table1.xlsx, replace

