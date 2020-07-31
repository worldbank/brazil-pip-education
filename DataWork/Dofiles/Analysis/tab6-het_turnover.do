
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Heterogeneity analysis by teacher turnover 			   *		  
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										   	   *
*																			   *
********************************************************************************

	** OUTLINE:			Generate dummy for high turnover at baseline
						Run regressions on learning
						Run regressions on progression
						Export table
	
	** REQUIRES:		"${master_dt_fin}/master_teacherlevel.dta"
	
						"${master_dt_fin}/master_studentlevel.dta"
						"${master_dt_fin}/RN_students_panel.dta"
						"${master_dt_fin}/master_schoollevel.dta"
						
	** CREATES:			Table 6: Impact on Student Learning and Progression by Teacher Turnover at Baseline
						"${master_tab}/tab6-het_turnover.tex"
									
* ---------------------------------------------------------------------------- *
*						 Generate dummy for high turnover at baseline		   *
* ---------------------------------------------------------------------------- */
	
	use					"${master_dt_fin}/master_studentlevel.dta", clear
	
	preserve
		
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
		
	restore

	merge m:1 inep using `turnoverDummies', nogen keep(match)
				
* ---------------------------------------------------------------------------- *
*						Run regressions on learning	  		 	   			   *
* ---------------------------------------------------------------------------- *

	* Drop all stored estimation results
	est clear
	
	foreach 	 subject 		in media {
	
		* Save estimates of regression with teacher turnover interaction on the overall sample (using only z-scores)
		eststo  `subject'_all	 	   : reghdfe prof_`subject' school_treated##high_turnover	///
									   , abs(strata) cl(inep)
			
		* Add number of clusters, mean and standard deviation of the control group to the stored estimates
		estadd  scalar cl_all	 	   =  e(N_clust)
		
		estadd  scalar diff_all		   = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.high_turnover]

		test    1bn.school_treated 	   + 1bn.school_treated#1bn.high_turnover = 0
		estadd  scalar p_diff_all 		   = r(p)

		* Same estimates by grade
		foreach   				 grade  in 6 {
				
			* Define type of "ensino"
			if   				`grade' ==	 1  local ensino EM
			else			  				    local ensino EF
			
			eststo `subject'_grade`grade'	 : 	reghdfe prof_`subject' school_treated##high_turnover	///
											 if grade == `grade' & pool_`grade'`ensino'					///
												 ,  abs(polo) cl(inep)
			estadd  scalar cl_grade`grade' 	 =  e(N_clust)
			
			estadd  scalar diff_grade`grade' 		     = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.high_turnover]

			test    1bn.school_treated 	   + 1bn.school_treated#1bn.high_turnover = 0
			estadd  scalar p_diff_grade`grade'  		   = r(p)
		}	
	}
	
* ---------------------------------------------------------------------------- *
*						Run regressions on progression 		 	   			   *
* ---------------------------------------------------------------------------- *
	
	use  "${master_dt_fin}/RN_students_panel.dta", clear
	
	keep if inlist(student_grade , 5, 6, 10)
	
	replace  	   student_grade = 1 if student_grade == 10

	rename  	   student_grade grade
	
	merge m:1 inep grade using "${master_dt_fin}/master_schoollevel.dta", ///
			  nogen keep(match) keepusing(school_treated *rate* strata)
	
	distinct inep
	
	keep if  year == 2016
		
	local 	 studentVars promoted dropped retained
	
	merge m:1 inep using `turnoverDummies', nogen assert(master match)
	
	* Store regressions results with promotion, drop-out, and retention rate
	foreach rateType of local studentVars {
	 	
		eststo 	`rateType'_all: ///
		reghdfe `rateType' school_treated##high_turnover, abs(strata) cl(inep)
		estadd  scalar  cl_all	 	   =  e(N_clust)
		
		estadd scalar   diff_all = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.high_turnover]
		
		test   1bn.school_treated + 1bn.school_treated#1bn.high_turnover = 0
		estadd scalar p_diff_all = r(p)
					
		foreach grade in 6 {
			
			eststo 	`rateType'_grade`grade': ///
			reghdfe `rateType' school_treated##high_turnover if grade == `grade', abs(strata) cl(inep)
			estadd  scalar cl_grade`grade' 	  =  e(N_clust)
			
			estadd scalar   diff_grade`grade' = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.high_turnover]
			test   1bn.school_treated + 1bn.school_treated#1bn.high_turnover = 0
			estadd scalar p_diff_grade`grade' = r(p)
		}
	}
		
* ---------------------------------------------------------------------------- *
*									Export table	  		 	   			   *
* ---------------------------------------------------------------------------- *

	* List names of estimates stored
	est dir
	
	* Close all open files
	file close _all
	
	* Save separate sample regression results in a unique LaTeX file for the paper	
	foreach sample in all grade6 {
				
		#d	;
			esttab media_`sample'
				promoted_`sample'
				 dropped_`sample'
				retained_`sample'
			using "${master_tab}/het_turnover_`sample'"
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
								  
			stats(N cl_`sample' diff_`sample' p_diff_`sample'
				  , lab("\addlinespace[0.75em] Number of observations"
						"Number of clusters"
						"\addlinespace[0.75em] \multicolumn{5}{l}{\textit{Total effect:} Treatment $+$ Treatment $\times$ High teacher turnover at baseline} \\ \hspace{10pt} $\sum \hat{\beta}$"
						"\hspace{10pt} P-value")
					fmt(0 0 %9.3f %9.3f)
				  )
			star(* 0.10 ** 0.05 *** 0.01)
			
			b(%9.3f) se(%9.3f)
			;
		#d	cr
	}

	* Initiate final LaTeX file
	file open test using "${master_tab}/het_turnover.tex", text write replace
			
	* Append estimations in unique LaTeX file
	foreach sample in all grade6 {
		
		file open test_`sample' using "${master_tab}/het_turnover_`sample'.tex", text read

		* Loop over lines of the LaTeX file and save everything in a local
		local `sample' ""
			file  read test_`sample' line						
		while r(eof)==0 {    
			local `sample' `" ``sample'' `line' "'
			file read  test_`sample' line
		}
			file close test_`sample'
		
		sleep  ${sleep}
		erase "${master_tab}/het_turnover_`sample'.tex"
	}
		
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write test
			 "&\multicolumn{1}{c}{\textit{Learning}}   &\multicolumn{3}{c}{\textit{Progression}} \\		  " _n
			 " \cmidrule(lr){2-2}					    \cmidrule(lr){3-5}					   	 	      " _n
			 "&(1)     								   &(2)    &(3)	    &(4)	 			   	 \\	      " _n
			 "&Average 								   &Passed &Dropped &Retained			     \\ 	  " _n
			 "&test score 							   &	   &out	    &			 		     \\ \hline" _n
			 "\multicolumn{5}{c}{\textbf{All schools}} 						  	 			 	 \\ \hline" _n
		     "`all' 																			    \hline" _n
		     "\multicolumn{5}{c}{\textbf{6th  grade -- Lower secondary schools}} 				 \\ \hline" _n
			 "`grade6' \hline 																	    \hline" _n
		;
	#d	cr
	
		file close test
	
	* Remove spaces between rows
	filefilter "${master_tab}/het_turnover.tex"			/// 
			   "${master_tab}/tab6-het_turnover.tex"	///
			   , from("[1em]") to("") replace
	sleep  	    ${sleep}
	erase 	   "${master_tab}/het_turnover.tex"
	
	* Add link to the file (filefilter does not provide it automatically"
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tab6-het_turnover.tex":${master_tab}/tab6-het_turnover.tex}"'
	
	
******************************** End of do-file ********************************
