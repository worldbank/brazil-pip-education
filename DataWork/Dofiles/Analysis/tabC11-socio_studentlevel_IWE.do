		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate effect on socio-emotional skills			   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019										  	   *
*																			   *
********************************************************************************
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:	   		Table C11: Impact on Socio-Emotional Skills - Interaction-Weighted Estimator
						"${master_tab}/tabC11-socio_studentlevel_IWE.tex"

* ---------------------------------------------------------------------------- */
	
	* Load master data at the student level
	use "${master_dt_fin}/master_studentlevel", clear
	
	* Drop all stored estimation results
	est clear
	
	* Store regressions results with standardized test scores
	foreach 	 skill 		in agreeab consc extrav neurot openness {
	
		preserve
		keep if !mi(z_`skill'_c) & !mi(school_treated) & !mi(strata)
		// This doesn't solve the issue
		
		* Save estimates of regression on the overall sample (using only z-scores)
		eststo  `skill'_all	 	   : GSSUtest z_`skill'_c school_treated strata,	///
										 cluster(inep)
		// The code is not running because in strata 10 (i.e. for grade 1) as
		// there is no variation in treatment assigment.
		// In other words, we only have data on test scores for treated schools
		// Therefore, the beta estimate is equal to 0
		
		* Same estimates by grade
		foreach   				 grade  in 5 6 1 {
			
			* Define type of "ensino"
			if   				`grade' ==	 1  local ensino EM
			else			  				    local ensino EF
			
			eststo `skill'_grade`grade'	 : 	GSSUtest z_`skill'_c school_treated strata	///
										 if grade == `grade' & pool_`grade'`ensino'		/// actually, the grade perfectly matches the 'pool' variable, so no need to put a double condition...
										 ,  cluster(inep)
		}
		
		restore 
	}
		
	* List names of estimates stored
	est dir
	
	* Close all open files
	file close _all

	* Save separate sample regression results in a unique LaTeX file for the paper	
	foreach sample in all grade5 grade6 grade1 {
			
		* Specify `esttab` options
		#d	;
		
			local  	options
				  " replace tex se fragment
					nodepvars nonumbers nomtitles nolines noobs nonotes
					alignment(c)
					coeflabel(school_treated "Treatment")
					stats(pchange W_p pval
						  , lab("Percentage difference between IWE and OLS"
								"P-value for joint test of equality between IWE and OLS"
								"P-value for joint Wald Test for interactions")
							fmt(%9.3f %9.3f %9.3f))
					star(* 0.10 ** 0.05 *** 0.01)
					keep(school_treated)
					b(%9.3f) se(%9.3f)
				  "
			;
								
			* Save results in LaTeX (by sample used) ;
			esttab agreeab_`sample'
				   consc_`sample'
				   extrav_`sample'
				   neurot_`sample'
				   openness_`sample'
			using "${master_tab}/socio_`sample'"
			, `options'
			;
		#d	cr
	}

	* Initiate final LaTeX file
	file open  test											///
		 using "${master_tab}/socio_studentlevel_IWE.tex"	///
	   , text write replace
			
	* Append estimations in unique LaTeX file
	foreach sample in all grade5 grade6 grade1 {
		
		file open 	test_`sample'							///
			 using "${master_tab}/socio_`sample'.tex"		///
			 , text read
																			
		* Loop over lines of the LaTeX file and save everything in a local
		local `sample' ""
			file  read test_`sample' line
		while r(eof)==0 {
			local `sample' `" ``sample'' `line' "'
			file read  test_`sample' line
		}
			file close test_`sample'
		
		sleep  ${sleep}
		erase "${master_tab}/socio_`sample'.tex"
	}
		
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write test
			 
			 "&(1)  		 &(2)     		    &(3)      	  &(4)  	   &(5) 	 \\		  "	_n
			 "&Agreeableness &Conscientiousness &Extroversion &Neuroticism &Openness \\ \hline"	_n
			 "\multicolumn{6}{c}{\textbf{All schools}} 								 \\ \hline"	_n
			 "`all' \hline"																		_n
			 "\multicolumn{6}{c}{\textbf{5th  grade  -- Primary schools}}			 \\ \hline"	_n
			 "`grade5' \hline"																	_n
			 "\multicolumn{6}{c}{\textbf{6th  grade  -- Lower secondary schools}}	 \\ \hline"	_n
			 "`grade6' \hline"																	_n
			 "\multicolumn{6}{c}{\textbf{10th  grade -- Upper secondary schools}} 	 \\ \hline"	_n
			 "`grade1' \hline															\hline"	_n
		;
	#d	cr
	
	file close test
	
	* Remove spaces
	filefilter "${master_tab}/socio_studentlevel_IWE.tex"			/// 
			   "${master_tab}/tabC11-socio_studentlevel_IWE.tex"	///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/socio_studentlevel_IWE.tex"
	
	* Add link to the file (filefilter does not provide it automatically)
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabC11-socio_studentlevel_IWE.tex":${master_tab}/tabC11-socio_studentlevel_IWE.tex}"'

	
******************************** End of do-file ********************************
