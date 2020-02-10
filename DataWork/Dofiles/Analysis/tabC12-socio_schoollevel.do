		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate effect on socio-emotional at the school level *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019										  	   *
*																			   *
********************************************************************************

	** OUTLINE:			
	
	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						
	** CREATES:	   		Table C12: Impact on Socio-Emotional Skills - School Level Regressions
						"${master_tab}/tabC12_promotion_other_grades.tex"
			
	** NOTES:

* ---------------------------------------------------------------------------- *
*							School level regression				   			   *
* ---------------------------------------------------------------------------- */

	* Load master data at the school level
	use "${master_dt_fin}/master_schoollevel", clear
	
	* Drop all stored estimation results
	est clear
	
	* Store regressions results recoded for conscientiousness vignette
	foreach 	skill  in 		   agreeab consc extrav neurot openness {
	
		* Save estimates of regression on the overall sample
		eststo `skill'_all		 : reghdfe z_`skill'_c school_treated [aw=school_N_students], abs(strata) vce(rob)
				
		sum    `skill'_c		if e(sample) == 1 & school_treated == 0
		estadd  scalar mean_all	 = r(mean)
		estadd  scalar sd_all	 = r(sd)
		
		* Same estimates by grade
		foreach   				 grade  in 5 6 1 {
			
			* Define type of "ensino"
			if   				`grade' ==	 1  local ensino EM
			else			  				    local ensino EF
			
			eststo `skill'_grade`grade'		 : 	reghdfe z_`skill'_c school_treated 		///
											   [aw=school_N_students]					///
											 if grade == `grade' & pool_`grade'`ensino'	/// actually, the grade perfectly matches the 'pool' variable, so no need to put a double condition...
											 ,  abs(strata) vce(rob)
			sum    `skill'_c				 if e(sample) == 1 & school_treated == 0
			estadd  scalar mean_grade`grade' =  r(mean)
			estadd  scalar sd_grade`grade' 	 =  r(sd)
		}
	}
	
	* List names of estimates stored
	est dir
	
	* Close all open files
	file close _all

	* Save separate regression results in a unique LaTeX file for the paper
	* --------------------------------
	
	* Loop over set of separate LaTeX files
	foreach sample in all grade5 grade6 grade1 {
		
		* Specify `esttab` options
		#d	;
		
			local  	options
				  " replace tex se fragment
					nodepvars nonumbers nomtitles nolines noobs nonotes
					alignment(c)
					coeflabel(school_treated "Treatment")
					stats(N mean_`sample' sd_`sample'
						  , lab("Number of observations"
								"Mean dep.\ var.\ control group"
								"SD dep.\ var.\ control group")
							fmt(0 %9.3f %9.3f))
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
	file open  socio									///
		 using "${master_tab}/socio_schoollevel.tex"	///
		 , text write replace
	
	* Append estimations in unique LaTeX file
	foreach sample in all grade5 grade6 grade1 {
		
		file open 	socio_`sample'						///
			 using "${master_tab}/socio_`sample'.tex"	///
			 , text read
			
		* Loop over lines of the LaTeX file and save everything in a local
		local `sample' ""																	
			file  read socio_`sample' line									
		while r(eof)==0 { 																	
			local `sample' `" ``sample'' `line' "'											
			file read  socio_`sample' line									
		}																					
			file close socio_`sample'										
		
		erase "${master_tab}/socio_`sample'.tex"						
	}																						
	
	* Append all locals as strings, add footnote and end of LaTeX environments				
	#d	;
		file write socio
			
			 "&(1)  		 &(2)     		    &(3)      	  &(4)  	   &(5) 	 \\		  "	_n
			 "&Agreeableness &Conscientiousness &Extraversion &Neuroticism &Openness \\ \hline"	_n
			 "\multicolumn{6}{c}{\textbf{All schools}}				     			 \\ \hline"	_n
			 "`all'    \hline"																	_n
			 "\multicolumn{6}{c}{\textbf{5th  grade -- Primary schools}} 			 \\ \hline"	_n
			 "`grade5' \hline"																	_n
			 "\multicolumn{6}{c}{\textbf{6th  grade -- Lower secondary schools}}  	 \\ \hline"	_n
			 "`grade6' \hline"																	_n
			 "\multicolumn{6}{c}{\textbf{10th grade -- Upper secondary schools}}	 \\ \hline"	_n
			 "`grade1' \hline \hline"															_n
		;
	#d	cr
	
	file close socio
	
	* Remove spaces
	filefilter "${master_tab}/socio_schoollevel.tex"		///
			   "${master_tab}/tabC12-socio_schoollevel.tex"	///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/socio_schoollevel.tex"
	
	* Add link to the file (filefilter does not provide it automatically)
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabC12-socio_schoollevel.tex":${master_tab}/tabC12-socio_schoollevel.tex}"'

	
******************************** End of do-file ********************************
