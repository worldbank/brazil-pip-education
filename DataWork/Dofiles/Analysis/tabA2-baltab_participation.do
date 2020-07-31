
/*******************************************************************************
*						PIP								   					   *
*																 			   *
*  PURPOSE:  			Balance table on test participation			   		   *
*  WRITTEN BY:  		Matteo Ruzzante [mruzzante@worldbank.org]		   	   *
*  Last time modified:  July 2020											   *
*																			   *
********************************************************************************
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
												
	** CREATES:			Table A2: Balance in Socio-Emotional and Proficiency Test Participation
						"${master_tab}/tabA2-baltab_participation.tex"
				
* --------------------------------------------------------------------------- */
		
	* Load master data at the student level
	use "${master_dt_fin}/master_studentlevel.dta", clear
		
	* Reset estimates and file handles
	est  clear
	file close _all
		
	* Chech that variable 'n_alunos' is correct
	bys	   inep				  : gen test = _N
	assert school_N_students ==     test
	drop 				 		    test
	
	* Identify number of students in classes which were assigned to socio-emotional tests
	egen socio 			= rowmean(agreeab_c consc_c extrav_c neurot_c openness_c)
	egen class_assigned = max(!mi(socio)), by(inep turma)
	
	bys  inep turma: gen class_N_students = _N
		
	* Manually generate percentage of non-missing socio-emotional skills and test scores
	foreach var in socio proficiencia_media {
		
		if "`var'" == "socio" 				{
			local condition "if class_assigned == 1"
			local classId	"turma"
			local countVar  "class_N_students"
		}
		if "`var'" == "proficiencia_media"	{
			local condition ""
			local classId	""
			local countVar  "school_N_students"
		}
		
		egen 	  all_missing_`var'	=   min(missing(`var')) 			, by(inep)
		recode	  all_missing_`var' (0 = 1) (1 = 0)
		
		egen	count_missing_`var' = 		  count(`var')  `condition' , by(inep `classId')			 
		gen       pct_missing_`var' = count_missing_`var' / `countVar'
				
		distinct inep if all_missing_`var'
		distinct inep if all_missing_`var' & school_treated == 0
		distinct inep if all_missing_`var' & school_treated == 1
	}
	
		sum 	  pct_missing*
		
	* Collapse data by school
	collapse (mean)  student_age student_gender student_bolsa_familia 			///
					 all_missing* pct_missing* school_treated grade			 	///
					 school_N_students class_N_students							///
			 (count) socio proficiencia_media, by(inep polo)
		
	sum all_missing* pct_missing* socio proficiencia_media, sep(10)
	
	drop 	socio proficiencia_media
	
	replace pct_missing_socio 			   = . if pct_missing_socio 			 == 0
	replace pct_missing_proficiencia_media = . if pct_missing_proficiencia_media == 0
	
	rename  pct_missing_* * 
	sum					socio			   ///
						proficiencia_media
	
	lab var all_missing_socio 	   		   "\addlinespace[0.5em] \textit{Participating schools}"
	lab var all_missing_proficiencia_media "\addlinespace[0.5em] \textit{Participating schools}"
	
	lab var socio 	   		   			   "\addlinespace[0.5em] \textit{Percentage of test takers}"
	lab var proficiencia_media 			   "\addlinespace[0.5em] \textit{Percentage of test takers}"
	//variable labels we want to use as headers in LaTeX are too long
	//(and therefore are trunctated to 80 characters):
	//to avoid this, we keep the label string shorter here and 
	//replace the strings after having generated the table with [iebaltab, browse]
	
	* Reshape variables by grade treated
	gen 	 	 grade_str =  ""
	replace 	 grade_str =  "5th" if grade == 5
	replace  	 grade_str =  "6th" if grade == 6
	replace	 	 grade_str = "10th" if grade == 1
		
	foreach 	 	 depVar in socio proficiencia_media {
		
		local 	 	 balVars "all_missing_`depVar'"
				
		foreach  	 grade in "5th" "6th" "10th"	 {
			
			gen 	 all_miss_`depVar'_`grade' = all_missing_`depVar' ///
			if 		 grade_str == "`grade'" & !mi(grade)
			
			lab var  all_miss_`depVar'_`grade' "\hspace{1em} `grade' grade"
			
			local 	 balVars " `balVars' all_miss_`depVar'_`grade' "
	
		}
		
		local 	 	 balVars " `balVars' `depVar' "
		
		foreach  	 grade in "5th" "6th" "10th"	 {
			gen 	`depVar'_`grade' 			= `depVar' 	  ///
			if 		 grade_str == "`grade'" & !mi(grade)
			lab var `depVar'_`grade' "\hspace{1em} `grade' grade"
			local 	 balVars " `balVars' `depVar'_`grade' "
		}
		
		cap mat drop _all
		
		* Loop on outcome variables
		foreach var of local balVars {
		
			* Compute randomization inference p-values
			ritest school_treated _b[school_treated], 				///
			reps($repsNum) seed($seedsNum) strata(polo) nodots:		///
			areg `var' school_treated, a(polo) cl(inep)
			
			* And store them in a matrix (with a space before or after the cell)
			mat ri_pvalues = nullmat(ri_pvalues) \ r(p)
			mat ri_pvalues = nullmat(ri_pvalues) \ .		
		}
		
		preserve
	
			#d	;
				iebaltab `balVars',
						  vce(robust) grpvar(school_treated) fixedeffect(polo)
						  total
						  grplabels(1 Treatment @ 0 Control)
						  rowvarlabels
						  pttest starsnoadd
						  tblnonote
						  browse
						  replace
				;	
			#d	cr
			
			drop in   1/3
			
			* Fix lables
			replace v1 = "\addlinespace[0.5em] \textit{Participating schools}     \\[1em] \hspace{1em} All schools" if v1 == "\addlinespace[0.5em] \textit{Participating schools}"
			replace v1 = "\addlinespace[0.5em] \textit{Percentage of test takers} \\[1em] \hspace{1em} All schools" if v1 == "\addlinespace[0.5em] \textit{Percentage of test takers}"
			
			* Replace parentheses for standard errors
			forv varNum = 3(2)7 {
				
				replace v`varNum' = subinstr(v`varNum',"[","(",.)
				replace v`varNum' = subinstr(v`varNum',"]",")",.)
			}
			
			* Mover total in the first place
			rename v7 total
			rename v6 total_N
			
			rename v5 v7
			rename v4 v6
			rename v3 v5
			rename v2 v4
			
			rename    total   v3
			rename    total_N v2
					
			* Here, if you need, you can merge more results, which you had produced and stored in other temporary files
			* Say, if you want to add another column, `iebaltab` does not allow to add automatically, so you would have to created it and them merge it here
			* ...
			
			* Retrieve RI p-values from matrix
			svmat 	 ri_pvalues
			
			* Generate p-values string to match `baltab` formatting
			gen		 v9 = string(ri_pvalues1 ,  "%9.3f")
			replace  v9 = ""  if ri_pvalues1 == .
			drop				 ri_pvalues1
			//you can play with this variable if you want to move it in other positions of the table
			//or add parentheses
			
			* Order variables
			order  v1 v2 v3 v4 v5 v6 v7 v8 v9
					
			* Save LaTeX file containing results		
			local 								   `depVar'_fileCount = 0
			dataout, save("${master_tab}/`depVar'_``depVar'_fileCount'.tex") 	///
						 replace tex nohead noauto	
			
		restore
		
		foreach lineToRemove in "\BSdocumentclass[]{article}"					///
								"\BSsetlength{\BSpdfpagewidth}{8.5in}" 			///
								"\BSsetlength{\BSpdfpageheight}{11in}"  		///
								"\BSbegin{document}" 							///
								"\BSend{document}" 								///
								"\BSbegin{tabular}{lcccccccc}"					///
								"Variable"										///
								"\BShline"										///
								"\BSend{tabular}"								{
		
			filefilter "${master_tab}/`depVar'_``depVar'_fileCount'.tex"		/// 
					   "${master_tab}/`depVar'_`=``depVar'_fileCount'+1'.tex"	///
					   , from("`lineToRemove'") to("") replace
			sleep	    ${sleep}
			erase	   "${master_tab}/`depVar'_``depVar'_fileCount'.tex"
		
			local `depVar'_fileCount = ``depVar'_fileCount' + 1
		}
	
		file open  `depVar'File													///
			 using "${master_tab}/`depVar'_``depVar'_fileCount'.tex"			///
			 , text read		
															
		local 	   `depVar'File ""											
		file read  `depVar'File line																	
		while r(eof) == 0 {    
			local 	  `depVar'File " ``depVar'File' `line' "
			file read `depVar'File line
		}
		file close `depVar'File
		
		sleep  ${sleep}
		erase "${master_tab}/`depVar'_``depVar'_fileCount'.tex"
	}

	* Make table
	file  open finalFile using "${master_tab}/tabA2-baltab_participation.tex"	///
		, text write replace
		
	#d	;
	
		file write finalFile																																		_n
			" 		   			 & (1) & (2)     & (3) & (4) 	 & (5) & (6)       & (7)     & (8)	   \\[1.5ex]				  " _n
			"\textit{Variable}   &     & Total   &     & Control &     & Treatment & T-test  & RI      \\ 		  	  			  " _n
			"\hspace{1em} Sample &  N  & Mean/SE &  N  & Mean/SE &  N  & Mean/SE   & P-value & P-value \\[1.5ex] \hline 		  " _n
			"\addlinespace[0.5ex] \multicolumn{9}{c}{\textbf{Panel A -- Socio-emotional tests}} 	   \\[0.5ex] \hline 		  " _n
			"`socioFile' 																				 [1.8ex] \hline 		  " _n
			"\addlinespace[0.5ex] \multicolumn{9}{c}{\textbf{Panel B -- Proficiency tests}}	   		   \\[0.5ex] \hline 		  " _n
			"`proficiencia_mediaFile'																	 [1.8ex] \hline 		  " _n
			" 																									 \hline \\[-1.5ex]" _n
		;
	#d	cr
	
	file close finalFile

	
******************************** End of do-file ********************************	
