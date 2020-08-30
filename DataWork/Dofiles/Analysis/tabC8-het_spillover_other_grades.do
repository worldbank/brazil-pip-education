
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Spillover heterogeneity analysis by teacher turnover   *		  
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2020										   	   *
*																			   *
********************************************************************************

	** OUTLINE:			Generate dummy for high turnover at baseline
						Run regressions on progression
						Export table
	
	** REQUIRES:		"${master_dt_fin}/master_teacherlevel.dta"
	
						"${master_dt_fin}/RN_students_panel.dta"						
						"${master_dt_fin}/master_schoollevel.dta"
						
	** CREATES:			Table C8: Impact on Other Grades in 6th Grade Treated Schools - Heterogeneity by Teacher Turnover at Baseline
						"${master_tab}/tabC8-het_spillover_other_grades.tex"
									
* ---------------------------------------------------------------------------- *
*						 Generate dummy for high turnover at baseline		   *
* ---------------------------------------------------------------------------- */
	
	use 			"${master_dt_fin}/master_teacherlevel.dta", clear
		
	keep   if grade == grade_of_interest

	collapse 		turnover_rate_*, by(inep grade)
	
	keep inep grade turnover_rate_2016
	
	gen 		low_turnover   = .
	gen 	   high_turnover   = .
	
	foreach 	grade in 5 6 1 {
	
		sum 		   		    turnover_rate_2016  if grade == `grade', d
		
		scalar  									   median_turnover_rate_grade`grade' = `r(p50)'
		replace  low_turnover = turnover_rate_2016  <  median_turnover_rate_grade`grade'    ///
						 if !mi(turnover_rate_2016) &  grade == `grade'
		replace high_turnover = turnover_rate_2016  >= median_turnover_rate_grade`grade'    ///
						 if !mi(turnover_rate_2016) &  grade == `grade'
	}
	
	keep   *_turnover inep
	tempfile turnoverDummies
	save	`turnoverDummies'

* ---------------------------------------------------------------------------- *
*						Run regressions on progression 		 	   			   *
* ---------------------------------------------------------------------------- *
	
	* Load panel tracking students across census waves
	use   "${master_dt_fin}/RN_students_panel.dta", clear
	
	* Keep students in upper-elementary school
	keep  if  inlist(student_grade , 6, 7, 8, 9)
		
	* Keep PIP schools	
	merge m:1 inep  using "${master_dt_fin}/master_schoollevel.dta", ///
			  nogen keep(match) keepusing(school_treated *rate* strata grade)
	
	* Keep schools that participate to the experiment with 6th grade
	keep  if  grade == 6 & year == 2016
	
	* Merge high-turnover-at-baseline dummy	
	merge m:1 inep using `turnoverDummies', nogen keep(master match)
	
	* Store regressions results with promotion, drop-out, and retention rate
	local 	  studentVars promoted dropped retained
	
	foreach   rateType of local studentVars {
			
		forv  grade = 7/9 {
				
			   eststo  `rateType'_grade`grade': ///
			   reghdfe `rateType' school_treated##high_turnover if student_grade == `grade', abs(strata) cl(inep)
			   estadd   scalar cl	  =  e(N_clust)
			
			   estadd   scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.high_turnover]
			   test     1bn.school_treated + 1bn.school_treated#1bn.high_turnover = 0
			   estadd   scalar p_diff = r(p)
		}
	
		#d	;
			esttab `rateType'_grade7 `rateType'_grade8 `rateType'_grade9
			using "${master_tab}/`rateType'.tex"
				
				,
				
				replace tex se fragment
				nodepvars nonumbers nomtitles nolines noobs nonotes
				alignment(c)
				
				keep(	  1.school_treated
						  1.school_treated#1.high_turnover
										   1.high_turnover
						  _cons)
				order(	  1.school_treated
						  1.school_treated#1.high_turnover
										   1.high_turnover
						  _cons)
				coeflabel(1.school_treated 			   	   "Treatment"
						  1.school_treated#1.high_turnover "Treatment $\times$ High teacher turnover at baseline"
										   1.high_turnover "High teacher turnover at baseline"
						  _cons								"\addlinespace[0.5em] Constant")
									  
				stats(N cl diff p_diff
					  , lab("\addlinespace[0.75em] Number of observations"
							"Number of clusters"
							"\addlinespace[0.75em] \multicolumn{4}{l}{\textit{Total effect:} Treatment $+$ Treatment $\times$ High teacher turnover at baseline} \\ \hspace{10pt} $\sum \hat{\beta}$"
							"\hspace{10pt} P-value")
						fmt(0 0 %9.3f %9.3f)
					  )
				star(* 0.10 ** 0.05 *** 0.01)
				
				b(%9.3f) se(%9.3f)
			;
		#d	cr
	}
	
	file close _all
	
	file open progression using "${master_tab}/het_spillover_other_grades.tex", text write replace
					
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
			 
 			 "&(1) &(2) &(3) 													 \\	        " _n
			 "&7th &8th &9th 													 \\ \hline  " _n
			 
			 "\multicolumn{4}{c}{\textit{Probability of student passing}} 		 \\ \hline  " _n
			 "`promoted' \hline"												     	      _n
			 "\multicolumn{4}{c}{\textit{Probability of student dropping out}}   \\ \hline  " _n
			 "`dropped'  \hline"															  _n
			 "\multicolumn{4}{c}{\textit{Probability of student being retained}} \\ \hline  " _n
			 "`retained' \hline 													\hline  " _n
			 "																	 \\ [-1.8ex]"
			;
	#d	cr
	
	file close progression
	
	* Remove spaces
	filefilter "${master_tab}/het_spillover_other_grades.tex"		/// 
			   "${master_tab}/tabC8-het_spillover_other_grades.tex"	///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/het_spillover_other_grades.tex"
	
	* Add link to the file (filefilter does not provide it automatically"
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabC8-het_spillover_other_grades.tex":"${master_tab}/tabC8-het_spillover_other_grades.tex"}"'


******************************** End of do-file ********************************
