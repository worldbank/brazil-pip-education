		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate effect on teacher turnover					   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										  	   *
*																			   *
********************************************************************************

	** OUTLINE:			Estimate effect on teacher turnover
						Generate dummy for high turnover at baseline
						Interact treatment with turnover at baseline
						Join panels and export final table
	
	** REQUIRES:   		"${master_dt_fin}/turnover_teacherlevel_wide.dta"
						
	** CREATES:	   		Table 5: Impact on Probability of Teacher Staying in the Same School
						"${master_tab}/tab5-turnover_teacherlevel.tex"

* ---------------------------------------------------------------------------- *
*					 Estimate effect on teacher turnover	 				   *
* ---------------------------------------------------------------------------- */

	* Load data at the teacher level
	use "${master_dt_fin}/master_teacherlevel.dta", clear
	
	keep if grade == grade_of_interest
	
	eststo  all 		: reghdfe repeat_2017 school_treated	///
						, abs(strata) cl(inep)
	estadd scalar N_cl  = e(N_clust)
	sum	   repeat_2017 if e(sample) & school_treated == 0
	estadd scalar mean  = r(mean)
	estadd scalar sd    = r(sd)

	foreach grade in 5 6 1  {
	
		eststo grade`grade' : reghdfe repeat_2017 school_treated ///
						   if grade == `grade'					///
						    , abs(strata) cl(inep) 
		estadd scalar N_cl  = e(N_clust)
		sum    repeat_2017 if e(sample) == 1 & school_treated == 0
		estadd scalar mean  = r(mean)
		estadd scalar sd    = r(sd)
	}
		
	#d	;
		esttab  all grade5 grade6 grade1
				using "${master_tab}/turnover.tex",
				replace tex se fragment
				nodepvars nonumbers nomtitles nolines noobs nonotes alignment(c)
				coeflabel(school_treated "Treatment")
				stats(N N_cl mean sd,
					  lab("\addlinespace[0.5em] Number of observations"
						  "Number of clusters"
						  "\addlinespace[0.5em] Mean dep.\ var.\ control group"
						  "SD dep.\ var.\ control group")
					  fmt(0 0 %9.3f %9.3f))
				star(* 0.10 ** 0.05 *** 0.01)
				keep(school_treated)
				b(%9.3f) se(%9.3f)
		;
	#d	cr

* ---------------------------------------------------------------------------- *
*					Generate dummy for high turnover at baseline			   *
* ---------------------------------------------------------------------------- *
	
	preserve
		
		collapse 		turnover_rate_*, by(inep grade)
		
		keep inep grade turnover_rate_2016
		
		gen 		low_turnover   = .
		gen 	   high_turnover   = .
		
		foreach 	grade in 5 6 1 {
		
			sum 		   		   turnover_rate_2016 if grade == `grade', d
			
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

	merge m:1 inep using `turnoverDummies', nogen assert(match)
	
* ---------------------------------------------------------------------------- *
*					Interact treatment with turnover at baseline		   	   *
* ---------------------------------------------------------------------------- *
	
	est    clear
	
	eststo all  		: reghdfe repeat_2017 school_treated##1.high_turnover  		///
						, abs(strata) cl(inep)
	
	* Add p-value of treatment + interaction term to estimation scalars
	estadd scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.high_turnover]
	
	test   1bn.school_treated + 1bn.school_treated#1bn.high_turnover = 0
	estadd scalar p_diff = r(p)
	
	sum	   repeat_2017  if e(sample) == 1 & school_treated == 0 & high_turnover == 0
	estadd scalar mean_0 = r(mean)
	sum	   repeat_2017  if e(sample) == 1 & school_treated == 0 & high_turnover == 1
	estadd scalar mean_1 = r(mean)
	
	foreach grade in 5 6 1 {
		
		* For 5th grade, we want to have an empty column in the table
		if `grade' == 5 {
				
			* So we run a fake regression
			eststo grade`grade' : reg inep inep_teacher, nocons
		}
		
		else {
		
			eststo grade`grade' : reghdfe repeat_2017 1.school_treated##1.high_turnover 	///
							   if grade == `grade'											///
								, abs(strata) cl(inep) 
			
			estadd scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.high_turnover]
			
			test   1bn.school_treated + 1bn.school_treated#1bn.high_turnover = 0
			estadd scalar p_diff = r(p)
			
			sum	   repeat_2017  if e(sample) == 1 & school_treated == 0 & high_turnover == 0
			estadd scalar mean_0 = r(mean)
			sum	   repeat_2017  if e(sample) == 1 & school_treated == 0 & high_turnover == 1
			estadd scalar mean_1 = r(mean)
		}
	}
		
	#d	;
		esttab  all grade5 grade6 grade1
				using "${master_tab}/turnover_het.tex",
				
				replace tex
				se fragment
				nodepvars nonumbers nomtitles nolines
				noobs nonotes alignment(c)
				
				keep(	  1.school_treated
						  1.school_treated#1.high_turnover
										   1.high_turnover
						  _cons)
				order(	  1.school_treated
						  1.school_treated#1.high_turnover
										   1.high_turnover
						  _cons)
				coeflabel(1.school_treated 				   "Treatment"
						  1.school_treated#1.high_turnover "Treatment $\times$ High teacher turnover rate at baseline"
										   1.high_turnover			   		  "High teacher turnover rate at baseline"
						  _cons												  "\addlinespace[0.5em] Constant")
				stats(diff p_diff mean_1 mean_0,
					  lab("\addlinespace[0.75em] \multicolumn{5}{l}{\textit{Total effect on schools with high turnover at baseline:} Treatment $+$ Treatment $\times$ high-turnover dummy} \\ \hspace{10pt} $\sum \hat{\beta}$"
						  "\hspace{10pt} P-value"
						  "\addlinespace[0.75em] \multicolumn{5}{l}{\textit{Unconditional mean of the dependent variable in the control group:}} \\ \hspace{10pt} Schools with high turnover at baseline"
						  "\hspace{10pt} Schools with low turnover at baseline")
					  fmt(%9.3f %9.3f %9.3f %9.3f)
					  )
				star(* 0.10 ** 0.05 *** 0.01)
				b(%9.3f) se(%9.3f)
		;
	#d	cr
	
* ---------------------------------------------------------------------------- *
*						Join panels and export final table				   	   *
* ---------------------------------------------------------------------------- *
		
	* Close all open files
	file close _all
	
	file open  turnover_table using "${master_tab}/turnover_teacherlevel.tex", 	///
			   text write replace
				
	* Add incipit
	file write turnover_table 
			
	* Append estimations in unique LaTeX file 										
	foreach model in "" _het {															
		
		file open turnover`model' using "${master_tab}/turnover`model'.tex", text read
																					
		* Loop over lines of the LaTeX file and save everything in a local			
		local turnover`model' ""															
			file read turnover`model' line													
		while r(eof)==0 { 															
			local turnover`model' `" `turnover`model'' `line' "'									
			file read  turnover`model' line													
		}																			
			file close turnover`model'														
		
		sleep  ${sleep}
		erase "${master_tab}/turnover`model'.tex" 										
	}																				
				
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write turnover_table	
			 
			 "&(1) &(2) &(3) &(4)  																		   \\	   		    " _n
			 "&All &5th &6th &10th 																		   \\ 		  \hline" _n
			 "\addlinespace[0.25em] \multicolumn{5}{c}{\textbf{Panel A -- Overall impact}} 	 		 	   \\[0.25em] \hline" _n
			 "\addlinespace[0.5em]  `turnover' 							   		   			  				 [0.75em] \hline" _n
			 "\addlinespace[0.25em] \multicolumn{5}{c}{\textbf{Panel B -- Impact by turnover at baseline}} \\[0.25em] \hline" _n
			 "\addlinespace[0.5em]  `turnover_het' 		  				     		 							      \hline" _n
			 "\hline \\ [-1.8ex]"
		;	
	#d	cr
	
	file close turnover_table
		
	* Remove spaces
	filefilter "${master_tab}/turnover_teacherlevel.tex"		/// 
			   "${master_tab}/tab5-turnover_teacherlevel.tex"	///
			   , from("[1em]") to("") replace
	sleep  		${sleep}
	erase 	   "${master_tab}/turnover_teacherlevel.tex"
	
	* Add link to the file (filefilter does not provide it automatically"
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tab5-turnover_teacherlevel.tex":${master_tab}/tab5-turnover_teacherlevel.tex"}"'

	
******************************** End of do-file ********************************
