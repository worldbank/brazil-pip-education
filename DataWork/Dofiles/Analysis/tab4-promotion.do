		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate effect on progression rates				   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										  	   *
*																			   *
********************************************************************************

	** OUTLINE:			School-level regressions (SIGEduc data)
						Student-level regressions (census data)
	
	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						"${master_dt_fin}/RN_students_panel.dta"
						
	** CREATES:	   		Table 4: Impact on Student Progression Rate
						"${master_tab}/tab4-promotion.tex"
			
* ---------------------------------------------------------------------------- *
*							School level regression				   			   *
* ---------------------------------------------------------------------------- */
	
	* Load master data at the school level
	use	"${master_dt_fin}/master_schoollevel", replace
	
	* Count number of schools
	count
	
	* Drop all stored estimation results
	est clear
		
	local schoolPrefix promotion dropout retention
	
	* Store regressions results with promotion, drop-out, and retention rate
	foreach rateType of local schoolPrefix {
	 	
		if "`rateType'" == "promotion" local rateTypeStudent "promoted"
	 	if "`rateType'" == "dropout"   local rateTypeStudent "dropped"
		if "`rateType'" == "retention" local rateTypeStudent "retained"
		
		eststo 	`rateType'_all: ///
		reghdfe `rateType'_rate_2016 school_treated, abs(strata) vce(rob)
		
		sum 	`rateType'_rate_2016   if e(sample) == 1 & school_treated == 0
		estadd   scalar mean_`rateTypeStudent' = r(mean) 
		estadd   scalar sd_`rateTypeStudent'   = r(sd)

		foreach grade in 5 6 1 {
			eststo 	`rateType'_grade`grade': ///
			reghdfe `rateType'_rate_2016 school_treated if grade == `grade', abs(strata) vce(rob)
			sum  	`rateType'_rate_2016 if e(sample) == 1 & school_treated == 0
			estadd   scalar mean_`rateTypeStudent' = r(mean) 
			estadd   scalar sd_`rateTypeStudent'   = r(sd)
		}
	 }
	 
* ---------------------------------------------------------------------------- *
*							Student level regression				   		   *
* ---------------------------------------------------------------------------- *	

	use  "${master_dt_fin}/RN_students_panel.dta", clear
	
	keep if inlist(student_grade , 5, 6, 10)
	
	replace  	   student_grade = 1 if student_grade == 10

	rename  	   student_grade grade
	
	merge m:1 inep grade using "${master_dt_fin}/master_schoollevel.dta", ///
			  nogen keep(match) keepusing(school_treated *rate* strata)
	
	distinct inep
	
	keep if  year == 2016
	
	*save "${master_dt_int}/PIP_students.dta", replace
	
	local 	 studentVars promoted dropped retained
	
	* Turn to percentage points
	foreach  rateType of local studentVars {
	
		replace `rateType' = `rateType' * 100
	}
	
	* Check correlations between school and student level progression rates
	preserve
	
		collapse `studentVars' promotion_rate_2016 dropout_rate_2016 retention_rate_2016, by(inep grade)
		
		corr     `studentVars' promotion_rate_2016 dropout_rate_2016 retention_rate_2016
	
		corr	 promoted 	   promotion_rate_2016
		corr	 dropped 	   dropout_rate_2016
		corr	 retained 	   retention_rate_2016
		
	restore
			
	* Store regressions results with promotion, drop-out, and retention rate
	foreach rateType of local studentVars {
	 	
		eststo 	`rateType'_all: ///
		reghdfe `rateType' school_treated, abs(strata) cl(inep)
		
		sum 	`rateType' if e(sample) == 1 & school_treated == 0
		estadd   scalar mean_`rateType' = r(mean) 
		estadd   scalar sd_`rateType'   = r(sd)

		foreach grade in 5 6 1 {
			eststo 	`rateType'_grade`grade': ///
			reghdfe `rateType' school_treated if grade == `grade', abs(strata) cl(inep)
			sum  	`rateType' if e(sample) == 1 & school_treated == 0
			estadd   scalar mean_`rateType' = r(mean) 
			estadd   scalar sd_`rateType'	= r(sd)
		}
	}
	
	foreach rateType of local studentVars {
	
		if "`rateType'" == "promoted" local schoolPrefix "promotion"
	 	if "`rateType'" == "dropped"  local schoolPrefix "dropout"
		if "`rateType'" == "retained" local schoolPrefix "retention"
		
		 #d	;
		esttab `schoolPrefix'_all `schoolPrefix'_grade5 `schoolPrefix'_grade6 `schoolPrefix'_grade1 
				   `rateType'_all	  `rateType'_grade5 	`rateType'_grade6     `rateType'_grade1 	 
				using "${master_tab}/`rateType'.tex",
				replace tex se fragment
				nodepvars nonumbers nomtitles nolines noobs nonotes alignment(c)
				coeflabel(school_treated "Treatment")
				stats(N N_clust mean_`rateType' sd_`rateType',
					  lab("Number of observations"
						  "Number of clusters"
						  "Mean dep.\ var.\ control group"
						  "SD dep.\ var.\ control group")
					  fmt(0 0 %9.2f %9.2f))
				star(* 0.10 ** 0.05 *** 0.01)
				keep(school_treated)
				b(%9.2f) se(%9.2f)
			;
		#d	cr
	}
	
	file close _all
	
	file open progression using "${master_tab}/promotion.tex", text write replace
					
	* Append estimations in unique LaTeX file 															
	foreach var of local studentVars {																	
		
		file open 	`var' using "${master_tab}/`var'.tex", text read
																										
		* Loop over lines of the LaTeX file and save everything in a local								
		local `var' ""																					
			file read  `var' line																		
		while r(eof)==0 { 																				
			local `var' `" ``var'' `line' "'															
			file read  `var' line																		
		}																								
			file close `var'																			
		
		sleep ${sleep}
		erase "${master_tab}/`var'.tex" 																
	}
			
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write progression
			 
			 "&\multicolumn{4}{c}{\textit{Grade level}} & \multicolumn{4}{c}{\textit{Student level}} \\" _n
			 "\cmidrule(lr){2-5} \cmidrule(lr){6-9} "													 _n
			 "&(1) &(2) &(3) &(4)  &(5) &(6) &(7) &(8)  \\		 " 										 _n
			 "&All &5th &6th &10th &All &5th &6th &10th \\ \hline"										 _n
			 "&\multicolumn{8}{c}{\textbf{Passing}}     \\ \hline"										 _n
			 "`promoted' \hline"																		 _n
			 "&\multicolumn{8}{c}{\textbf{Dropout}}     \\ \hline"										 _n
			 "`dropped'  \hline"																		 _n
			 "&\multicolumn{8}{c}{\textbf{Retention}}   \\ \hline" 										 _n
			 "`retained' \hline							   \hline \\ [-1.8ex]"							 _n
		;
	#d	cr
	
	file close progression
	
	* Remove spaces
	filefilter "${master_tab}/promotion.tex"		/// 
			   "${master_tab}/tab4-promotion.tex"	///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/promotion.tex"
	
	* Add link to the file (filefilter does not provide it automatically"
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tab4-promotion.tex":"${master_tab}/tab4-promotion.tex"}"'
	
******************************** End of do-file ********************************
