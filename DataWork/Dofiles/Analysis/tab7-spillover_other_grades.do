		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate spillover effects to other grades			   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019										  	   *
*																			   *
********************************************************************************

	** OUTLINE:			
	
	** REQUIRES:   		"${master_dt_fin}/master_teacherlevel.dta"
						"${master_dt_fin}/RN_students_panel.dta"
						"${master_dt_fin}/master_schoollevel.dta"
						
	** CREATES:	   		Table 7: Spillover to Other Grades in 6th Grade Treated Schools
						"${master_tab}/tab7-spillover_other_grades.tex"
			
	** NOTES:

* ---------------------------------------------------------------------------- */

	* Load data at the teacher level
	use 	"${master_dt_fin}/master_teacherlevel.dta", clear
	
	keep if grade_of_interest == 6
	
	foreach grade in 6 7 8 9 {
	
		eststo grade`grade' : reghdfe repeat_2017 school_treated ///
						   if grade == `grade' 					 ///
						    , abs(strata) cl(inep) 
		estadd scalar N_cl  = e(N_clust)
		sum    repeat_2017 if e(sample) == 1 & school_treated == 0
		estadd scalar mean  = r(mean)
		estadd scalar sd    = r(sd)
	}
		
	#d	;
		esttab  grade6 grade7 grade8 grade9
				using "${master_tab}/turnover.tex",
				replace tex se fragment
				nodepvars nonumbers nomtitles nolines noobs nonotes alignment(c)
				coeflabel(school_treated "Treatment")
				stats(N N_cl mean sd,
					  lab("Number of observations"
						  "Number of clusters"
						  "Mean dep.\ var.\ control group"
						  "SD dep.\ var.\ control group")
					  fmt(0 0 %9.3f %9.3f))
				star(* 0.10 ** 0.05 *** 0.01)
				keep(school_treated)
				b(%9.3f) se(%9.3f)
		;
	#d	cr

* ---------------------------------------------------------------------------- *

	use  "${master_dt_fin}/RN_students_panel.dta", clear
		
	keep if inlist(student_grade , 6, 7, 8, 9)
		
	merge m:1 inep  using "${master_dt_fin}/master_schoollevel.dta", ///
			  nogen keep(match) keepusing(school_treated *rate* strata grade)
	
	distinct inep
	
	keep if grade == 6 & year == 2016
		
	local 	 studentVars promoted dropped retained
	
	* Check correlations between school and student level progression rates
	preserve
	
		collapse `studentVars' promotion_rate_2016 dropout_rate_2016 retention_rate_2016, by(inep grade)
		
		corr     `studentVars' promotion_rate_2016 dropout_rate_2016 retention_rate_2016
	
		corr	 promoted 	   promotion_rate_2016
		corr	 dropped 	   dropout_rate_2016
		corr	 retained 	   retention_rate_2016
		
	restore
			
	* Store regressions results with promotion, drop-out, and retention rate
	foreach  rateType of local studentVars {
	 	
		forv grade = 6/9 {
		
			 eststo 	`rateType'_grade`grade': ///
			 reghdfe `rateType' school_treated if student_grade == `grade', abs(strata) cl(inep)
			 sum  	`rateType' if e(sample) == 1 & school_treated == 0
			 estadd   scalar mean_`rateType' = r(mean) 
			 estadd   scalar sd_`rateType'	= r(sd)
		}
	}
	
	foreach rateType of local studentVars {
	
		#d	;
		esttab `rateType'_grade6 `rateType'_grade7 `rateType'_grade8 `rateType'_grade9
				using "${master_tab}/`rateType'.tex",
				replace tex se fragment
				nodepvars nonumbers nomtitles nolines noobs nonotes alignment(c)
				coeflabel(school_treated "Treatment")
				stats(N N_clust mean_`rateType' sd_`rateType',
					  lab("Number of observations"
						  "Number of clusters"
						  "Mean dep.\ var.\ control group"
						  "SD dep.\ var.\ control group")
					  fmt(0 0 %9.3f %9.3f))
				star(* 0.10 ** 0.05 *** 0.01)
				keep(school_treated)
				b(%9.3f) se(%9.3f)
			;
		#d	cr
	}
	
	file close _all
	
	file open progression using "${master_tab}/spillover_other_grades.tex", text write replace
					
	* Append estimations in unique LaTeX file 															
	foreach var in turnover `studentVars' {																	
		
		file open 	`var' using "${master_tab}/`var'.tex", text read
																										
		* Loop over lines of the LaTeX file and save everything in a local								
		local `var' ""																					
			file read  `var' line																		
		while r(eof)==0 { 																				
			local `var' `" ``var'' `line' "'															
			file read  `var' line																		
		}																								
			file close `var'																			
		
		erase "${master_tab}/`var'.tex" 																
	}
			
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write progression
			 
 			 "&(1) &(2) &(3) &(4) 															  \\	     " _n
			 "&6th &7th &8th &9th 															  \\ \hline  " _n
			 "\multicolumn{5}{c}{\textbf{Panel A -- Teacher level}} 						  \\ [0.25em]" _n
			 "&\multicolumn{4}{c}{\textit{Probability of teacher staying in the same school}} \\ \hline  " _n
			 "`turnover' \hline 															  \\ \hline  " _n
			 "\multicolumn{5}{c}{\textbf{Panel B -- Student level}} 			  			  \\ [0.25em]" _n
			 "&\multicolumn{4}{c}{\textit{Probability of student being promoted}} 			  \\ \hline  " _n
			 "`promoted' \hline"																		   _n
			 "&\multicolumn{4}{c}{\textit{Probability of student dropping out}}   			  \\ \hline  " _n
			 "`dropped'  \hline"																		   _n
			 "&\multicolumn{4}{c}{\textit{Probability of student being retained}}			  \\ \hline  " _n
			 "`retained' \hline 																 \hline  " _n
			 "																				  \\ [-1.8ex]"
			;
	#d	cr
	
	file close progression
	
	* Remove spaces
	filefilter "${master_tab}/spillover_other_grades.tex"		/// 
			   "${master_tab}/tab7-spillover_other_grades.tex"	///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/spillover_other_grades.tex"
	
	* Add link to the file (filefilter does not provide it automatically"
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tab7-spillover_other_grades.tex":"${master_tab}/tab7-spillover_other_grades.tex"}"'

	
******************************** End of do-file ********************************
