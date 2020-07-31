
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			OLS treatment effect in terms of Prova Brasil		   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:
							
	** REQUIRES:   		"${master_dt_fin}/scores_rescaled_ProvaBrasil.dta"
						
	** CREATES:	   		Table C6: Impact on Student Learning - Standardized Test Scores Rescaled to SAEB
						"${master_tab}/tabC6-test_rescaled_studentlevel.tex"
			
	** NOTES:			
	
* ---------------------------------------------------------------------------- */

	* Load rescaled test scores
	use "${master_dt_fin}/scores_rescaled_ProvaBrasil.dta", clear
	
	* Drop all stored estimation results
	est clear
	
	* Store regressions results with standardized test scores
	foreach 	 subject 		in MT LT {
		
		* Save estimates of regression on the overall sample (using only z-scores)
		eststo  `subject'_all	 	   : reghdfe prof_`subject'_rescaled school_treated, ///
										 abs(strata) cl(inep)
		
		* Add number of clusters, mean and standard deviation of the control group to the stored estimates
		estadd  scalar cl_`subject'  			=  e(N_clust)
		
		sum     proficiencia_`subject'_rescaled if e(sample) == 1 & school_treated == 0
		estadd  scalar mean_`subject'	 	   	=  r(mean)
		estadd  scalar sd_`subject'	 	   		=  r(sd)
		
		* Same estimates by grade
		foreach   				 grade  in 5 6 9 1 3 {
			
			* Define treated grade
			if 					`grade' == 5		  local grade_treated = 5
			if			 inlist(`grade'  ,	 6,9	) local grade_treated = 6
			if   		 inlist(`grade'  ,		 1,3) local grade_treated = 1
						
			eststo `subject'_grade`grade'	 : 	reghdfe prof_`subject'_rescaled school_treated		///
											 if grade == `grade' & grade_treated == `grade_treated' /// 
											 ,  abs(strata) cl(inep)

			sum     proficiencia_`subject'_rescaled if e(sample) == 1 & school_treated == 0
			estadd  scalar mean_`subject' 			=  r(mean)
			estadd  scalar sd_`subject'	 			=  r(sd)
		}
		
		* Export tables for math and Portuguese to LaTex
		#d	;
			esttab  `subject'_grade5 `subject'_grade6 `subject'_grade9 `subject'_grade1 `subject'_grade3
					using "${master_tab}/`subject'_rescaled.tex",
					replace tex se fragment
					nodepvars nonumbers nomtitles nolines noobs nonotes alignment(c)
					coeflabel(school_treated "Treatment")
					stats(N N_clust mean_`subject' sd_`subject',
						  lab("Number of observations"
							  "Number of clusters"
							  "Mean dep. var. control group"
							  "SD dep. var. control group")
						  fmt(0 0 %9.3f %9.3f))
					star(* 0.10 ** 0.05 *** 0.01)
					keep(school_treated)
					b(%9.3f) se(%9.3f)
			;
		#d	cr
		
	}
	
	file close _all
	
	file open  rescaled											///
		 using "${master_tab}/test_rescaled_studentlevel.tex"	///
	   , text write replace
								
	* Append estimations in unique LaTeX file
	foreach subject in MT LT {
		
		file open 	`subject'									///
			 using "${master_tab}/`subject'_rescaled.tex"		///
			 , text read

		* Loop over lines of the LaTeX file and save everything in a local
		local `subject' ""
			file read  `subject' line
		while r(eof)==0 {
			local `subject' `" ``subject'' `line' "'
			file read  `subject' line
		}
			file close `subject'
		
		sleep  ${sleep}
		erase "${master_tab}/`subject'_rescaled.tex"
	}
			
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write rescaled	
						
			 "&(1) &(2) &(3) &(4)  &(5)  \\" 									 					  _n
			 "&5th &6th &9th &10th &12th \\ \cmidrule(lr){2-2} \cmidrule(lr){3-4} \cmidrule(lr){5-6}" _n
			 "\multicolumn{6}{c}{\textbf{Math}}       \\ \hline"									  _n
			 "`MT' \hline"																		 	  _n
			 "\multicolumn{6}{c}{\textbf{Portuguese}} \\ \hline"								      _n
			 "`LT' \hline \hline"																	  _n
		;
	#d	cr
	
	file close rescaled
	
	* Remove spaces
	filefilter "${master_tab}/test_rescaled_studentlevel.tex"			/// 
			   "${master_tab}/tabC6-test_rescaled_studentlevel.tex"		///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/test_rescaled_studentlevel.tex"
	
	* Add link to the file (filefilter does not provide it automatically)
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabC6-test_rescaled_studentlevel.tex":"${master_tab}/tabC6-test_rescaled_studentlevel.tex"}"'

	
******************************** End of do-file ********************************
	