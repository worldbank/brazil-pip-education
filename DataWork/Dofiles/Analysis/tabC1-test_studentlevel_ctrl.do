		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate effect on standardized test scores			   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019										  	   *
*																			   *
********************************************************************************

	** OUTLINE:			
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:	   		Table C1: Impact on Student Learning - Controlling for Students' Characteristics
						"${master_tab}/tabC1-test_studentlevel_ctrl.tex"
			
	** NOTES:

* --------------------------------------------------------------------------- */

	* Load master data at the student level
	use "${master_dt_fin}/master_studentlevel", clear
	
	* Set controls here
	local 		 studentCtrl 	   student_gender student_age i.student_race						///
								   student_bolsa_familia student_school_transport
	
	* Drop all stored estimation results
	est clear
	
	* Store regressions results with standardized test scores
	foreach 	 subject 		in media MT LT CH CN {
	
		* Save estimates of regression on the overall sample (using only z-scores)
		eststo  `subject'_all	 	   : reghdfe prof_`subject' school_treated `studentCtrl', 		///
										 abs(strata) cl(inep)
		
		* Add number of clusters, mean and standard deviation of the control group to the stored estimates
		estadd  scalar cl_all	 	   =  e(N_clust)
		
		sum     proficiencia_`subject' if e(sample) == 1 & school_treated == 0
		estadd  scalar mean_all	 	   =  r(mean)
		estadd  scalar sd_all	 	   =  r(sd)
		
		* Same estimates by grade
		foreach   				 grade  in 5 6 1 {
			
			* Define type of "ensino"
			if   				`grade' ==	 1  local ensino EM
			else			  				    local ensino EF
			
			eststo `subject'_grade`grade'	 : 	reghdfe prof_`subject' school_treated `studentCtrl'	///
											 if grade == `grade' & pool_`grade'`ensino'				/// actually, the grade perfectly matches the 'pool' variable, so no need to put a double condition...
											 ,  abs(polo) cl(inep)
			estadd  scalar cl_grade`grade' 	 =  e(N_clust)
			sum     proficiencia_`subject' 	 if e(sample) == 1 & school_treated == 0
			estadd  scalar mean_grade`grade' =  r(mean)
			estadd  scalar sd_grade`grade' 	 =  r(sd)
		}
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
					stats(N cl_`sample' mean_`sample' sd_`sample'
						  , lab("Number of observations"
								"Number of clusters"
								"Mean dep.\ var.\ control group"
								"SD dep.\ var.\ control group")
							fmt(0 0 %9.3f %9.3f))
					star(* 0.10 ** 0.05 *** 0.01)
					keep(school_treated)
					b(%9.3f) se(%9.3f)
				  "
			;
								
			* Save results in LaTeX (by sample used) ;
			esttab media_`sample'
				   MT_`sample'
				   LT_`sample'
				   CH_`sample'
				   CN_`sample'
			using "${master_tab}/test_`sample'"
			, `options'
			;
		#d	cr
	}

	* Initiate final LaTeX file
	file open  test												///
		 using "${master_tab}/test_studentlevel_ctrl.tex"		///
		 , text write replace
	
	* Append estimations in unique LaTeX file
	foreach sample in all grade5 grade6 grade1 {
		
		file open 	test_`sample'								///
			 using "${master_tab}/test_`sample'.tex"			///
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
		erase "${master_tab}/test_`sample'.tex" 													
	}																								
		
	* Append all locals as strings, add footnote and end of LaTeX environments						
	#d	;
		file write test
		
			 "&(1)     &(2)  &(3)        &(4)  	   &(5) 	 			 		 \\	   	  "	_n
			 "&Average &Math &Portuguese &Human    &Natural  			 		 \\ 	  "	_n
			 "&        &	 	&		 &Sciences &Sciences 		 	 		 \\ \hline"	_n
			 "\multicolumn{6}{c}{\textbf{All schools}} 					 		 \\ \hline" _n
			 "`all' \hline"																	_n
			 "\multicolumn{6}{c}{\textbf{5th  grade -- Primary schools}} 		 \\ \hline"	_n
			 "`grade5' \hline"																_n
			 "\multicolumn{6}{c}{\textbf{6th  grade -- Lower secondary schools}} \\ \hline"	_n
			 "`grade6' \hline"																_n
			 "\multicolumn{6}{c}{\textbf{10th grade -- Upper secondary schools}} \\ \hline"	_n
			 "`grade1' \hline \hline"														_n
		;
	#d	cr
	
	file close test
	
	* Remove spaces
	filefilter "${master_tab}/test_studentlevel_ctrl.tex"		/// 
			   "${master_tab}/tabC1-test_studentlevel_ctrl.tex"	///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/test_studentlevel_ctrl.tex"
	
	* Add link to the file (filefilter does not provide it automatically)
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabC1-test_studentlevel_ctrl.tex":${master_tab}/tabC1-test_studentlevel_ctrl.tex}"'

******************************** End of do-file ********************************

