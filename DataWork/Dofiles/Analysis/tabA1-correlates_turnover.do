		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate correlations with teacher permanence		   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										  	   *
*																			   *
********************************************************************************

	** REQUIRES:   		"${master_dt_fin}/Brazil_school_indicators.dta"
						
	** CREATES:	   		Table A1: Effect of Teacher Permanence on Education Outcomes in Brazil
						"${master_tab}/tabA1-correlates_turnover.tex"

* --------------------------------------------------------------------------- */
	
	* Load clean INEP data
	use   "${master_dt_fin}/Brazil_school_indicators.dta" , clear
	
	* Select outcome variables
	local outcomeVars    			school_TDI 		 ///
									school_promotion school_retention school_dropout
	
	* Standardize explanatory variable
	sum	  school_MIRD_y2015
	gen   school_MIRD_y2015_std = ( school_MIRD_y2015 - `r(mean)' ) / `r(sd)'
	sum	  school_MIRD_y2015_std
	
	* Standardize explanatory variable
	foreach ensinoLevel in ef em {
		
		local estList_`ensinoLevel' ""
		
		foreach outcomeVar of local outcomeVars {
				
			eststo `outcomeVar'_`ensinoLevel'_fe : ///
			  areg `outcomeVar'_`ensinoLevel'_y2015 school_MIRD_y2015_std , cl(uf_name) abs(uf_name)
			
			sum    `outcomeVar'_`ensinoLevel'_y2015 if e(sample) == 1
			estadd  scalar mean 			     = r(mean)
			estadd  scalar sd				     = r(sd)
			
			estadd  local  stateFE 	   			   "\checkmark"
			
			local   estList_`ensinoLevel' `" `estList_`ensinoLevel'' `outcomeVar'_`ensinoLevel'_fe "'
		}
		
		#d	;
			esttab `estList_`ensinoLevel''
					
					using "${master_tab}/correlates_turnover_`ensinoLevel'.tex",
					
					replace tex
					se nocons fragment
					nodepvars nonumbers nomtitles nolines noobs nonotes
					alignment(c)
					coeflabel(school_MIRD_y2015_std "\addlinespace[0.75em] Teacher permanence index")
					stats(	  N N_clust r2_a mean sd stateFE,
					  lab(	  "\addlinespace[0.75em] Number of observations"
							  "Number of clusters"
							  "Adjusted R-squared"
							  "\addlinespace[0.75em] Mean dep.\ var."
							  "SD dep.\ var."
							  "\addlinespace[0.75em] State fixed effects"
						  )
					  fmt(0 0 %9.3f %9.2f %9.2f)
						 )
					star(* 0.10 ** 0.05 *** 0.01)
					b(%9.2f) se(%9.2f)
			;
		#d	cr
	}
	
	file close _all
	
	* Initiate final LaTeX file
	file open correlates  using "${master_tab}/correlates_turnover.tex", 		 ///
		 text write replace
		
	* Append estimations in unique LaTeX file 								
	foreach sample in ef em {						
		
		file open correlates_`sample' using "${master_tab}/correlates_turnover_`sample'.tex", ///
			 text read
																				
		* Loop over lines of the LaTeX file and save everything in a local		
		local 	  correlates_`sample' ""														
			file read  correlates_`sample' line										
		while r(eof)==0 { 														
			local 	   correlates_`sample' `" `correlates_`sample'' `line' "'								
			file read  correlates_`sample' line										
		}																		
			file close correlates_`sample'										
		
		sleep  ${sleep}
		erase "${master_tab}/correlates_turnover_`sample'.tex" 								
	}																			
	
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write correlates
			 
			 "& (1) 	   & (2) 	 & (3)		 & (4)  							  \\ 		  				   " _n
			 "& Age-grade  & Passing & Retention & Dropout							  \\      	   	               " _n
			 "& distortion & rate    & rate      & rate 							  \\		 \hline            " _n
			 " \multicolumn{5}{c}{\textbf{\textit{Ensino Fundamental} -- Grades 1-9}} \\ 	     \hline            " _n
			 " `correlates_ef' 														  \\[-1ex]   \hline 		   " _n
			 " \multicolumn{5}{c}{\textbf{\textit{Ensino Medio} -- Grades 10-12}}	  \\         \hline \\[-3.5ex] " _n
			 " `correlates_em' 														  \\[-2.5ex] \hline 		   " _n
			 "																					 \hline \\[-2ex]   "
		;
	#d	cr
	
	file close correlates
		
	* Clean up table
	filefilter  "${master_tab}/correlates_turnover.tex"  		///
				"${master_tab}/tabA1-correlates_turnover.tex" , ///
				from("[1em]") to("") replace	
	sleep  		 ${sleep}
	erase 		"${master_tab}/correlates_turnover.tex" 	
	
	* Add link to the file (filefilter does not provide it automatically)
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabA1-correlates_turnover.tex":${master_tab}/tabA1-correlates_turnover.tex}"'

	
******************************** End of do-file ********************************
	