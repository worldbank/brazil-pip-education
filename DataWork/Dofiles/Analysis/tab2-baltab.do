
/*******************************************************************************
*						PIP								   					   *
*																 			   *
*  PURPOSE:  			Balance table 	  	   						   		   *
*  WRITTEN BY:  		Matteo Ruzzante [mruzzante@worldbank.org]		   	   *
*  Last time modified:  May 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			Balance of school and grade characteristics (at baseline, i.e. 2015)
						Balance of teacher and student characteristics (in the intervention, i.e. 2016)
	
	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						"${master_dt_fin}/master_teacherlevel.dta"
						"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:			Table 2: Balance Table
						"${master_tab}/tab2-baltab.tex"
			
	** NOTES:

* ---------------------------------------------------------------------------- *
*							School characteristics							   *
* ---------------------------------------------------------------------------- */
{		
	* Load school census data in 2015 (year prior to the intervention)
	use   		 "${master_dt_fin}/master_schoollevel.dta", clear
	
	* Reset estimates and file handles
	est   		 clear
	file  		 close _all
	
	* Keep characteristics of interest
	local 		 schoolIdentifiers 		inep school_treated polo grade strata pip_project

	local 		 schoolCharacteristics	school_internet school_library school_science_lab school_location
	local		 schoolNumbers			school_employees school_students school_classes school_student_class
	
	local		 schoolVars				///
				`schoolCharacteristics' ///
				 haversine_dist_km		///
				`schoolNumbers'
				
	keep		`schoolIdentifiers' 	///
				`schoolVars'
	 
	* Label variables
	lab var  	 school_internet 		"Has access to internet"
	lab var  	 school_library 		"Has library"
	lab var  	 school_science_lab		"Has sciences lab"
	lab var  	 school_location		"Located in urban area"
	lab var		 haversine_dist_km		"Distance to Natal (km)"
	lab var		 school_employees		"Number of employees"
	lab var		 school_students		"Number of students"
	lab var		 school_classes			"Number of classes"
	lab var		 school_student_class	"Students per class"
	
	* F-test for joint significance
	* -----------------------------
	
	* Run the regression for f-test
	areg school_treated `schoolVars', a(strata) rob

	* This F is calculated using fixed effects as well
	scalar reg_F 	= `e(F)'
	scalar reg_F_N 	= `e(N)'

	* Test all balance variables for joint significance
	testparm `schoolVars'
	scalar test_F 	= `r(F)'
	scalar test_F_p = `r(p)'
	
	test	 `schoolVars', mtest(bonferroni) 
	
	* Compute randomization inference p-values and store in matrix
	* ------------------------------------------------------------
	
	* Drop existing matrices
	cap mat drop ri_pvalues
		mat 	 ri_pvalues = .
	
	* Loop on outcome variables
	foreach var of local schoolVars {
		
		* Compute randomization inference p-values
		ritest school_treated _b[school_treated]	         , ///
		reps($repsNum) seed($seedsNum) strata(strata) nodots : ///
		areg `var' school_treated, a(strata) rob
		
		* And store them in a matrix (with a space before or after the cell)
		mat ri_pvalues = nullmat(ri_pvalues) \ r(p)
		mat ri_pvalues = nullmat(ri_pvalues) \ .
	}

	preserve
	
		#d	;
		
			// Run the actual `iebaltab' command and browse the results
			iebaltab `schoolVars'
					  ,
					  vce(robust) grpvar(school_treated) fixedeffect(strata)
					  grplabels(1 Treatment @ 0 Control)
					  rowvarlabels
					  pttest starsnoadd
					  tblnonote
					  browse
					  replace
			;
		#d	cr
		
		* Drop title raws
		drop in   1/3

		* Replace parentheses for standard errors
		replace v3 = subinstr(v3,"[","(",.)
		replace v5 = subinstr(v5,"[","(",.)
		replace v3 = subinstr(v3,"]",")",.)
		replace v5 = subinstr(v5,"]",")",.)
		
		* Temporary save the table output
		tempfile  all
		save	 `all'
		
	restore
	
	* Do the same for each separate grade
	foreach   				 grade  in 5 6 1 {
	
		cap mat drop ri_pvalues_grade`grade'
			mat		 ri_pvalues_grade`grade' = .
	
		foreach var of local schoolVars {
			
			ritest school_treated _b[school_treated]		   	 , ///
			reps($repsNum) seed($seedsNum) strata(strata) nodots : ///
			areg `var' school_treated if grade == `grade'		 , ///
			a(strata) rob
			
			mat ri_pvalues_grade`grade' = nullmat(ri_pvalues_grade`grade') \ r(p)
			mat ri_pvalues_grade`grade' = nullmat(ri_pvalues_grade`grade') \ .
		}
		
		preserve
			#d	;
				iebaltab `schoolVars'
						  if grade == `grade'
						  ,
						  vce(robust) grpvar(school_treated) fixedeffect(strata)
						  grplabels(1 Treatment @ 0 Control)
						  pttest starsnoadd
						  rowvarlabels
						  tblnonote
						  browse
						  replace
				;
			#d	cr
			
			* Keep only p-values
			drop   v1-v5
			drop   in 1/3
				
			rename * *_grade`grade'
			tempfile   grade`grade'
			save	  `grade`grade''
		
		restore
	}
	
	* Use/merge results
	use `all', clear
	foreach   				grade in 5 6 1 {
		merge 1:1 _n using `grade`grade'', nogen
	}
	
	* Retrieve RI p-values from matrix
	svmat 	 ri_pvalues
	
	* Generate p-values string to match `baltab` formatting
	gen		 ri_pvalues = string(ri_pvalues1, "%9.3f")
	
	* Add square brackets
	replace  ri_pvalues	= "[" +  ri_pvalues + "]"
	replace  v6			= 		 ri_pvalues 	  if ri_pvalues1 != .
	
	* Same for grade sample
	foreach   				grade in 5 6 1 {
		
		svmat 	 ri_pvalues_grade`grade'
		gen		 ri_pvalues_grade`grade' = string(ri_pvalues_grade`grade'1, "%9.3f")
		replace  ri_pvalues_grade`grade' = "[" +  ri_pvalues_grade`grade' + "]"
		replace  v6_grade`grade'   		 = 		  ri_pvalues_grade`grade'		if ri_pvalues_grade`grade'1 != .
	
	}
		
	drop 	 ri_pvalues*
	drop in  L
	
	* Start counter
	local 	 school_fileNum = 0
	
	* Save preliminary LaTeX file containing results
	dataout, save("${master_tab}/school_balance_`school_fileNum'.tex") ///
			 replace tex nohead noauto
}
* ---------------------------------------------------------------------------- *
*								Grade characteristics						   *
* ---------------------------------------------------------------------------- *
{	
	* Load school census data in 2015 (year prior to the intervention)
	use   		 "${master_dt_fin}/master_schoollevel.dta", clear
	
	* Merge teacher turnover at baseline, i.e., in 2016
	preserve
		
		use 	 "${master_dt_fin}/master_teacherlevel.dta", clear
		
		keep   if grade == grade_of_interest
		collapse 		turnover_rate_2016 , by(inep grade)
		
		keep inep grade turnover_rate_2016

		tempfile 		gradeTurnover
		save		   `gradeTurnover'
		
	restore

	merge 1:1 inep using `gradeTurnover', nogen assert(master match)
	
	* Reset estimates and file handles
	est   		 clear
	file  		 close _all
	
	local 		 gradeVars				///
				 promotion_rate_2015	///
				 dropout_rate_2015		///
				 retention_rate_2015	///
				 turnover_rate_2016
	
	lab var 	 promotion_rate_2015	"Passing rate"
	lab var   	 dropout_rate_2015		"Drop-out rate"
	lab var 	 retention_rate_2015	"Retention rate"
	lab var		 turnover_rate_2016		"Teacher turnover rate"

	cap mat drop ri_pvalues
		mat 	 ri_pvalues = .
	
	foreach var of local gradeVars {
		
		* Compute randomization inference p-values
		ritest school_treated _b[school_treated]	         , ///
		reps($repsNum) seed($seedsNum) strata(strata) nodots : ///
		areg `var' school_treated, a(strata) rob
		
		* And store them in a matrix (with a space before or after the cell)
		mat ri_pvalues = nullmat(ri_pvalues) \ r(p)
		mat ri_pvalues = nullmat(ri_pvalues) \ .
	}

	preserve
	
		#d	;
		
			iebaltab `gradeVars'
					  ,
					  vce(robust) grpvar(school_treated) fixedeffect(strata)
					  grplabels(1 Treatment @ 0 Control)
					  rowvarlabels
					  pttest starsnoadd
					  tblnonote
					  browse
					  replace
			;
		#d	cr
		
		drop in   1/3

		replace v3 = subinstr(v3,"[","(",.)
		replace v5 = subinstr(v5,"[","(",.)
		replace v3 = subinstr(v3,"]",")",.)
		replace v5 = subinstr(v5,"]",")",.)
		

		tempfile  all
		save	 `all'
		
	restore
	
	foreach   				 grade  in 5 6 1 {
	
		cap mat drop ri_pvalues_grade`grade'
			mat		 ri_pvalues_grade`grade' = .
	
		foreach var of local gradeVars {
			
			ritest school_treated _b[school_treated]		   	 , ///
			reps($repsNum) seed($seedsNum) strata(strata) nodots : ///
			areg `var' school_treated if grade == `grade'		 , ///
			a(strata) rob
			
			mat ri_pvalues_grade`grade' = nullmat(ri_pvalues_grade`grade') \ r(p)
			mat ri_pvalues_grade`grade' = nullmat(ri_pvalues_grade`grade') \ .
		}
		
		preserve
			#d	;
				iebaltab `gradeVars'
						  if grade == `grade'
						  ,
						  vce(robust) grpvar(school_treated) fixedeffect(strata)
						  grplabels(1 Treatment @ 0 Control)
						  pttest starsnoadd
						  rowvarlabels
						  tblnonote
						  browse
						  replace
				;
			#d	cr
			
			drop   v1-v5
			drop   in 1/3

			rename * *_grade`grade'
			tempfile   grade`grade'
			save	  `grade`grade''
		
		restore
	}
	
	use `all', clear
	foreach   				grade in 5 6 1 {
		merge 1:1 _n using `grade`grade'', nogen
	}
	
	svmat 	 ri_pvalues
	gen		 ri_pvalues = string(ri_pvalues1, "%9.3f")
	replace  ri_pvalues	= "[" +  ri_pvalues + "]"
	replace  v6			= 		 ri_pvalues 	  if ri_pvalues1 != .
	
	foreach   				grade in 5 6 1 {
		
		svmat 	 ri_pvalues_grade`grade'
		gen		 ri_pvalues_grade`grade' = string(ri_pvalues_grade`grade'1, "%9.3f")
		replace  ri_pvalues_grade`grade' = "[" +  ri_pvalues_grade`grade' + "]"
		replace  v6_grade`grade'   		 = 		  ri_pvalues_grade`grade'		if ri_pvalues_grade`grade'1 != .
	
	}
		
	drop 	 ri_pvalues*
	drop 	 in L
	
	* Start counter
	local 	 grade_fileNum = 0
	
	* Save preliminary LaTeX file containing results
	dataout, save("${master_tab}/grade_balance_`grade_fileNum'.tex") ///
			 replace tex nohead noauto
}	

* ---------------------------------------------------------------------------- *
*							Teacher characteristics							   *
* ---------------------------------------------------------------------------- *
{		
	* Load 2016 census data on teachers
	use  	  "${master_dt_fin}/master_teacherlevel.dta", clear
	
	keep   if 	   grade == grade_of_interest
	
	distinct  inep
	tab  		   grade			  , m
	
	* Generate dummies for balance table
	tab		  teacher_race 	 		  , m
	
	gen 	  teacher_white 	      = teacher_race 	  == 1 if 	  teacher_race > 0
	
	tab 	  teacher_schooling 	  , m
	gen 	  teacher_secondary 	  = teacher_schooling == 4 if !mi(teacher_schooling)
	
	tab 	  teacher_specialization  , m
	tab 	  teacher_master		  , m
	tab 	  teacher_nopostgrad	  , m
	
	gen   	  teacher_above_secondary = inlist(1, teacher_specialization, teacher_master)
	
	local 	  teacherVars 									///
			  teacher_age teacher_gender teacher_white 		///demographics
			  teacher_secondary teacher_above_secondary		 //education
	
	lab var   teacher_age 			  "Age"
	lab var   teacher_gender 		  "Gender (male $= 1$)"
	lab var   teacher_white 		  "White"
	lab var   teacher_secondary       "Has completed tertiary education"
	lab var   teacher_above_secondary "Has specialization and/or master"
				
cap mat drop  ri_pvalues
	mat  	  ri_pvalues = .
	
	foreach var of local teacherVars {
		
		ritest school_treated _b[school_treated], reps($repsNum) seed($seedsNum) strata(strata) nodots: ///
		areg `var' school_treated, a(strata) cl(inep)
		
		mat ri_pvalues = nullmat(ri_pvalues) \ r(p)
		mat ri_pvalues = nullmat(ri_pvalues) \ .
	}
	
	preserve
	
		#d	;
			iebaltab `teacherVars'
					  ,
					  vce(cluster inep) grpvar(school_treated) fixedeffect(strata)
					  grplabels(1 Treatment @ 0 Control)
					  pttest starsnoadd
					  rowvarlabels
					  tblnonote
					  browse
					  replace
			;
		#d	cr
		
		drop in   1/3
		
		replace v3 = subinstr(v3,"[","(",.)
		replace v5 = subinstr(v5,"[","(",.)
		replace v3 = subinstr(v3,"]",")",.)
		replace v5 = subinstr(v5,"]",")",.)
		
		tempfile  all
		save	 `all'
		
	restore
	
	foreach   				 	grade in 5 6 1 {
		
		cap mat drop ri_pvalues_grade`grade'
			mat		 ri_pvalues_grade`grade' = .
	
		foreach var of local teacherVars {
			
			ritest school_treated _b[school_treated], reps($repsNum) seed($seedsNum) strata(strata) nodots: ///
			areg `var' school_treated if grade == `grade', a(strata) cl(inep)
			
			mat ri_pvalues_grade`grade' = nullmat(ri_pvalues_grade`grade') \ r(p)
			mat ri_pvalues_grade`grade' = nullmat(ri_pvalues_grade`grade') \ .
		}
		
		preserve
			#d	;
				iebaltab `teacherVars'
						  if grade == `grade'
						  ,
						  vce(cluster inep) grpvar(school_treated) fixedeffect(strata)
						  grplabels(1 Treatment @ 0 Control)
						  pttest starsnoadd
						  rowvarlabels
						  tblnonote
						  browse
						  replace
				;
			#d	cr
			
			drop   v1-v5
			drop   in 1/3
			
			rename * *_grade`grade'
			tempfile   grade`grade'
			save	  `grade`grade''
		
		restore
	}
	
	use `all', clear
	foreach   				grade in 5 6 1 {
		merge 1:1 _n using `grade`grade'', nogen
	}
	
	svmat 	 ri_pvalues
	gen		 ri_pvalues = string(ri_pvalues1, "%9.3f")
	replace  ri_pvalues	= "[" +  ri_pvalues + "]"
	replace  v6			= 		 ri_pvalues 	  if ri_pvalues1 != .
	
	foreach   				grade in 5 6 1 {
		
		svmat 	 ri_pvalues_grade`grade'
		gen		 ri_pvalues_grade`grade' = string(ri_pvalues_grade`grade'1, "%9.3f")
		replace  ri_pvalues_grade`grade' = "[" +  ri_pvalues_grade`grade' + "]"
		replace  v6_grade`grade'   		 = 		  ri_pvalues_grade`grade'		if ri_pvalues_grade`grade'1 != .
	
	}
		
	drop ri_pvalues*
	drop in L
	
	local teacher_fileNum = 0
	
	dataout, save("${master_tab}/teacher_balance_`teacher_fileNum'.tex") ///
			 replace tex nohead noauto
}
* ---------------------------------------------------------------------------- *
*							Student characteristics							   *
* ---------------------------------------------------------------------------- *
{
	* Load master dataset at the student level
	use "${master_dt_fin}/master_studentlevel", clear
	
	local 	studentCharacteristics						///
			student_age 								///
			student_gender								///
			student_white  								///student_pardo student_black
			student_bolsa_familia 						 //student_school_transport
	
	keep   `schoolIdentifiers' student_uid				///
		   `studentCharacteristics'
			
	* Label variables which are not labeled yet
	lab var student_age 		  	 "Age"
	lab var student_gender 		 	 "Gender (male $= 1$)"
	lab var student_white			 "White"
   *lab var student_pardo			 "Pardo"
   *lab var student_black			 "Black"
	lab var student_bolsa_familia 	 "Receives \textit{Bolsa Família}"
   *lab var student_school_transport "Receives school transportation"
	
	* Keep only schools and grades in the sample
	keep if 	(pip_project == "EF1" & grade == 5) | ///
				(pip_project == "EF2" & grade == 6) | ///
				(pip_project == "EM"  & grade == 1)
	
	areg school_treated `studentCharacteristics', a(strata) cl(inep)

	scalar reg_F 	= `e(F)'
	scalar reg_F_N 	= `e(N)'

	testparm `studentCharacteristics'
	scalar test_F 	= `r(F)'
	scalar test_F_p = `r(p)'
	
	test	 `studentCharacteristics', mtest(bonferroni)
	
	cap mat drop ri_pvalues
		mat 	 ri_pvalues = .
	
	foreach var of local studentCharacteristics {
		ritest school_treated _b[school_treated]				      	   , ///
		reps($repsNum) seed($seedsNum) strata(strata) cluster(inep) nodots : ///
		areg `var' school_treated, a(strata) cl(inep)
		
		mat ri_pvalues = nullmat(ri_pvalues) \ r(p)
		mat ri_pvalues = nullmat(ri_pvalues) \ .
	}
	
	preserve
	
		#d	;
			iebaltab `studentCharacteristics'
					  ,
					  vce(cluster inep) grpvar(school_treated) fixedeffect(strata)
					  grplabels(1 Treatment @ 0 Control)
					  pttest starsnoadd
					  rowvarlabels
					  tblnonote
					  browse
					  replace
			;
		#d	cr
		
		drop in   1/3
		
		replace v3 = subinstr(v3,"[","(",.)
		replace v5 = subinstr(v5,"[","(",.)
		replace v3 = subinstr(v3,"]",")",.)
		replace v5 = subinstr(v5,"]",")",.)
		
		tempfile  all
		save	 `all'
		
	restore
	
	foreach   				 grade  in 5 6 1 {
		
		cap mat drop ri_pvalues_grade`grade'
			mat		 ri_pvalues_grade`grade' = .
	
		foreach var of local studentCharacteristics {
			
			ritest school_treated _b[school_treated]					  	   , ///
			reps($repsNum) seed($seedsNum) strata(strata) cluster(inep) nodots : ///
			areg `var' school_treated if grade == `grade'				  	   , ///
			a(strata) cl(inep) rob
			
			mat ri_pvalues_grade`grade' = nullmat(ri_pvalues_grade`grade') \ r(p)
			mat ri_pvalues_grade`grade' = nullmat(ri_pvalues_grade`grade') \ .
		}
		
		preserve
			#d	;
				iebaltab `studentCharacteristics'
						  if grade == `grade'
						  ,
						  vce(cluster inep) grpvar(school_treated) fixedeffect(strata)
						  grplabels(1 Treatment @ 0 Control)
						  pttest starsnoadd
						  rowvarlabels
						  tblnonote
						  browse
						  replace
				;
			#d	cr
			
			drop   v1-v5
			drop   in 1/3
			
			rename * *_grade`grade'
			tempfile   grade`grade'
			save	  `grade`grade''
		
		restore
	}
	
	use `all', clear
	foreach   				grade in 5 6 1 {
		merge 1:1 _n using `grade`grade'', nogen
	}
	
	svmat 	 ri_pvalues
	gen		 ri_pvalues = string(ri_pvalues1, "%9.3f")
	replace  ri_pvalues	= "[" +  ri_pvalues + "]"
	replace  v6			= 		 ri_pvalues 	  if ri_pvalues1 != .
	
	foreach   				grade in 5 6 1 {
		
		svmat 	 ri_pvalues_grade`grade'
		gen		 ri_pvalues_grade`grade' = string(ri_pvalues_grade`grade'1, "%9.3f")
		replace  ri_pvalues_grade`grade' = "[" +  ri_pvalues_grade`grade' + "]"
		replace  v6_grade`grade'   		 = 		  ri_pvalues_grade`grade'		if ri_pvalues_grade`grade'1 != .
	
	}
		
	drop ri_pvalues*
	drop in L
	
	local student_fileNum = 0
	
	dataout, save("${master_tab}/student_balance_`student_fileNum'.tex") ///
			 replace tex nohead noauto	
}
* ---------------------------------------------------------------------------- *
*									Final table						   		   *
* ---------------------------------------------------------------------------- *
{
	cap  file close _all
	
	foreach level in school grade teacher student {
		
		* Remove lines from `dataout` export
		foreach lineToRemove in "\BSdocumentclass[]{article}"			///
								"\BSsetlength{\BSpdfpagewidth}{8.5in}" 	///
								"\BSsetlength{\BSpdfpageheight}{11in}"  ///
								"\BSbegin{document}" 					///
								"\BSend{document}" 						///
								"\BSbegin{tabular}{lcccccccc}"			///
								"Variable"								///
								"\BShline"								///
								"\BSend{tabular}"						{
		
			filefilter "${master_tab}/`level'_balance_``level'_fileNum'.tex"		/// 
					   "${master_tab}/`level'_balance_`=``level'_fileNum'+1'.tex"	///
					   , from("`lineToRemove'") to("") replace
			erase	   "${master_tab}/`level'_balance_``level'_fileNum'.tex"
		
			local `level'_fileNum = ``level'_fileNum' + 1
		}
		
		* Add incipit and end of LaTeX table
		*(to be directly input in TeX document) without further formatting
		file open  `level'File												///
			 using "${master_tab}/`level'_balance_``level'_fileNum'.tex"	///
			 , text read		
															
		* Loop over lines of the original TeX file and save everything in a local
		local 	   `level'File ""											
		file read  `level'File line																	
		while r(eof) == 0 {    
			local 	  `level'File " ``level'File' `line' "
			file read `level'File line
		}
		file close `level'File
		
		* Erase original file
		erase "${master_tab}/`level'_balance_``level'_fileNum'.tex"
	}
	
	* Display locals
	di  "`schoolFile'"
	di   "`gradeFile'"
	di "`teacherFile'"
	di "`studentFile'"
	
	* Make final table
	file  open finalFile using "${master_tab}/tab2-baltab.tex"	///
		, text write replace
		
	#d	;
	
		file write finalFile
		
			"		   & \multicolumn{5}{c}{\textbf{All schools}} 		    			   & 5th Grade    & 6th Grade    & 10th Grade  		      \\ 		  	   " _n
			"			 \cmidrule(lr){2-6} \cmidrule(lr){7-7} \cmidrule(lr){8-8} \cmidrule(lr){9-9} 										      \\[-2ex] 	       " _n
			" 		   & (1)  		  & (2) 	& (3)			& (4) 		& (5)	       & (6) 	  	  & (7)	         & (8)				      \\ 		  	   " _n
			" 		   &   			  &  		&  				&  			& T-test       & T-test 	  & T-test       & T-test			      \\  		  	   " _n
			" 		   &   			  & Control &  				& Treatment & P-value	   & P-value 	  & P-value      & P-value 			      \\  		  	   " _n
			" Variable & N/[Clusters] & Mean/SE &  N/[Clusters] & Mean/SE   & [RI p-value] & [RI p-value] & [RI p-value] & [RI p-value]	\\ \hline \\[-2ex] 	       " _n
			"\multicolumn{9}{c}{\textbf{Panel A -- School characteristics}}																	      \\[0.5ex] \hline " _n
			"\addlinespace[0.75ex] `schoolFile' 																						   \hline \\[-2ex] 		   " _n
			"\multicolumn{9}{c}{\textbf{Panel B -- Grades assigned to the intervention}}													      \\[0.5ex] \hline " _n
			"\addlinespace[0.75ex] `gradeFile'																							   \hline \\[-2ex]		   " _n
			"\multicolumn{9}{c}{\textbf{Panel C -- Teacher characteristics}}																      \\[0.5ex] \hline " _n
			"\addlinespace[0.75ex] `teacherFile'																						   \hline \\[-2ex]	       " _n
			"\multicolumn{9}{c}{\textbf{Panel D -- Student characteristics}}																      \\[0.5ex] \hline " _n
			"\addlinespace[0.75ex] `studentFile'																												   " _n
			"																													    \hline \hline \\[-2ex]	       "
		;
	#d	cr
	
	file close finalFile
}

******************************** End of do-file ********************************	
