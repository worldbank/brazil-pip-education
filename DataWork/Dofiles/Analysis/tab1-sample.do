
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Randomization and sample allocation					   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			Calculate number of eligible schools by treatment group
						Calculate number of schools, which were effectively allocated to the experimental groups
						Calculate number of students
						
						Join numbers in 3-panel table
	
	** REQUIRES:   		"${master_dt_fin}/original_sample.dta"
						
	** CREATES:	   		Table 1: Sample
						"${master_tab}/sample.tex"
			
	** NOTES:
	
* ---------------------------------------------------------------------------- */

	* Load final database with all schools
	use "${master_dt_fin}/original_sample.dta", clear

* ---------------------------------------------------------------------------- *
*						Number of eligible schools				   			   *
* ---------------------------------------------------------------------------- *
	
	distinct inep
	//299 schools
	
	preserve
	
	* Keep only information on schools
	duplicates drop inep school_treated grade pool_1EM pool_5EF pool_6EF, force
	
		* Count number of schools per grade and treatment arm
		foreach grade in 5 6 {
			distinct inep if pool_`grade'EF == 1 & school_treated == 1
			scalar 	  t_`grade' =  r(ndistinct)
			distinct inep if pool_`grade'EF == 1 & school_treated == 0
			scalar 	  c_`grade' = r(ndistinct)
		}
			distinct inep if pool_1EM == 1 & school_treated == 1
			scalar 	  t_1		 = r(ndistinct)
			distinct inep if pool_1EM == 1 & school_treated == 0
			scalar	  c_1 	 	 = r(ndistinct)
		
		* Store statistics in scalar
		scalar total_5 = t_5 + c_5	
		scalar total_6 = t_6 + c_6	
		scalar total_1 = t_1 + c_1
		
		scalar treated = t_5 + t_6 + t_1	
		scalar control = c_5 + c_6 + c_1		
		
		scalar total   = control + treated
	
	* Restore data
	restore

* ---------------------------------------------------------------------------- *
*							Effective number of schools				   	   	   *
* ---------------------------------------------------------------------------- *

	* Keep only schools in the sample
	keep if (grade == 5 & pool_5EF == 1) | ///
			(grade == 6 & pool_6EF == 1) | ///actually, no observation is deleted, but we keep it as a check
			(grade == 1 & pool_1EM == 1) 
	
	preserve
	
	* Keep only information on schools
	duplicates drop inep school_treated grade pool_1EM pool_5EF pool_6EF, force
	
		* Count number of schools per grade and treatment arm
		foreach grade in 5 6 {
			sum inep  if grade == `grade' & pool_`grade'EF == 1 & school_treated == 1
			scalar 	  T_`grade' = r(N)
			sum inep  if grade == `grade' & pool_`grade'EF == 1 & school_treated == 0
			scalar 	  C_`grade' = r(N)
		}
			sum inep  if  grade == 1 & pool_1EM == 1 & school_treated == 1
			scalar 	  T_1		 = r(N)
			sum inep  if  grade == 1 & pool_1EM == 1 & school_treated == 0
			scalar	  C_1 	 	 = r(N)
		
		* Store statistics in scalar
		scalar TOTAL_5 = T_5 + C_5	
		scalar TOTAL_6 = T_6 + C_6	
		scalar TOTAL_1 = T_1 + C_1
		
		scalar TREATED = T_5 + T_6 + T_1	
		scalar CONTROL = C_5 + C_6 + C_1		
		
		scalar TOTAL   = CONTROL + TREATED
	
	* Restore data at the student level
	restore

* ---------------------------------------------------------------------------- *
*							Number of enrolled students		   	   	   		   *
* ---------------------------------------------------------------------------- *

	* Count number of students per grade and treatment arm
	foreach grade in 5 6 {
		sum inep  if  grade == `grade' & pool_`grade'EF == 1 & school_treated == 1
		scalar 	  t_a_`grade' = r(N)
		sum inep  if  grade == `grade' & pool_`grade'EF == 1 & school_treated == 0
		scalar 	  c_a_`grade' = r(N)
	}
		sum inep  if  grade == 1 & pool_1EM == 1 & school_treated == 1
		scalar    t_a_1 	 = r(N)
		sum inep  if  grade == 1 & pool_1EM == 1 & school_treated == 0
		scalar 	  c_a_1 	 = r(N)

	scalar total_a_5 = t_a_5 + c_a_5	
	scalar total_a_6 = t_a_6 + c_a_6	
	scalar total_a_1 = t_a_1 + c_a_1
	
	scalar treated_a = t_a_5 + t_a_6 + t_a_1
	scalar control_a = c_a_5 + c_a_6 + c_a_1
	
	scalar total_a	 = treated_a + control_a

* ---------------------------------------------------------------------------- *
*										TABLE		   	   	   		   		   *
* ---------------------------------------------------------------------------- *
	
	* Create unique LaTex table with three panels
	cap file close sample
		file open  sample using "${master_tab}/tab1-sample.tex", write replace
		
	#d	;
		file write sample
			"\begin{adjustbox}{max width=\textwidth}"								 		_n
				"\begin{tabular}{lccc} \hline \hline"  				  		  		 		_n
				
					"\multicolumn{4}{c}{\textbf{A) Number of eligible schools}}	 \\ \hline"	_n
					"			& Treatment     &   Control  	& Total \\ "			 	_n
					"\cmidrule(lr){2-4}"							   		 		 		_n 
					
					"5th  grade &" (t_5) 	   "&" (c_5) 	   "&" (total_5)   " \\ " 		_n
					"6th  grade &" (t_6) 	   "&" (c_6) 	   "&" (total_6)   " \\ " 		_n
					"10th grade &" (t_1) 	   "&" (c_1) 	   "&" (total_1)   " \\ " 		_n 
					
					"\cmidrule(lr){2-4}"  							   		  		 		_n
					"Total      &" (treated)   "&" (control)   "&" (total)     " \\ " 		_n
					"\hline \\ \hline"												 		_n
			
					"\multicolumn{4}{c}{\textbf{B) Effective number of schools}} \\ \hline"	_n
					"			& Treatment     &   Control  		& Total \\ "			_n
					"\cmidrule(lr){2-4}"							   		 		 		_n 
					
					"5th  grade &" (T_5) 	   "&" (C_5) 	   "&" (TOTAL_5)   " \\ " 		_n
					"6th  grade &" (T_6) 	   "&" (C_6) 	   "&" (TOTAL_6)   " \\ " 		_n
					"10th grade &" (T_1) 	   "&" (C_1) 	   "&" (TOTAL_1)   " \\ " 		_n 
					
					"\cmidrule(lr){2-4}"  							   		  		 		_n
					"Total     &" (TREATED)    "&" (CONTROL)   "&" (TOTAL)     " \\ " 		_n
					"\hline \\ \hline"														_n
					
					"\multicolumn{4}{c}{\textbf{C) Number of enrolled students}} \\ \hline"	_n
					"			&  Treatment    &   Control  	& Total 	     \\ " 		_n
					"\cmidrule(lr){2-4}"							   		 		 		_n 
					
					"5th  grade &" (t_a_5) 	   "&" (c_a_5)     "&" (total_a_5) " \\ " 		_n
					"6th  grade &" (t_a_6) 	   "&" (c_a_6)     "&" (total_a_6) " \\ " 		_n
					"10th grade &" (t_a_1) 	   "&" (c_a_1)     "&" (total_a_1) " \\ " 		_n 
					
					"\cmidrule(lr){2-4}"											 		_n
					"Total 	    &" (treated_a) "&" (control_a) "&" (total_a)   " \\ " 		_n
					
				"\hline \hline \end{tabular}"										 		_n
			"\end{adjustbox}"														 		_n
		;
	#d	cr
	
	file close sample

	
******************************** End of do-file ********************************	
