task create_unrelated_ped {

	File phenofile
	String memory

	command <<<
		echo PED,EGO,FA,MO,SEX > ped_head
		seq 1 $(tail -n +2 ${phenofile} | wc -l) > peds
		cut -d, -f1 <(tail -n +2 ${phenofile}) > egos
		paste peds egos | awk -v OFS=, '{print $1,$2,0,0,1}' > ped_no_head
		cat ped_head ped_no_head > ped
	>>>

	runtime {
		docker: "kwesterman/mmap-workflow:0.1"
		memory: "${memory} GB"
	}

	output {
		File out_ped = "ped"
	}
}
		
task create_binary_ped {

	File pedfile
	String memory

	command {
		$MMAP \
			--ped ${pedfile} \
			--compute_binary_relationship_matrix_by_groups \
			--binary_output_filename ped_bin
	}

	runtime {
		docker: "kwesterman/mmap-workflow:0.1"
		memory: "${memory} GB"
		continueOnReturnCode: [0, 1]
	}

	output {
		File out_ped_bin = "ped_bin"
	}
}

task run_interaction {

	File pedfile
	File bin_pedfile
	File phenofile
	String? phenotype_id
	String trait
	String covars
	String interaction_var
	File bin_dosefile
	String memory

	command {
		$MMAP \
			--ped ${pedfile} \
			--read_binary_covariance_file ${bin_pedfile} \
			--empirical_sandwich \
			--phenotype_filename ${phenofile} \
			${"--phenotype_id " + phenotype_id} \
			--trait ${trait} \
			--covariates ${covars} \
			--gxe_interaction ${interaction_var} \
			--binary_genotype_filename ${bin_dosefile} \
			--file_suffix results
	}

	runtime {
		docker: "kwesterman/mmap-workflow:0.1"
		memory: "${memory} GB"	
	}

	output {
		File out_res = "${trait}.results.mle.pval.slim.csv"
	}
}

workflow run_mmap {

	Array[File] bin_dosefiles
	#Int dosefile_skip_fields = 8
	File pedfile
	File phenofile
	String? phenotype_id
	String trait
	String covars
	String interaction_var
	String memory
	
	parameter_meta {
		bin_dosefiles: "name: bin_dosefiles, label: binary dosage files, help: array of MMAP binary genotype files (MxS format)"
		phenofile: "name: phenofile, label: phenotype file, help: comma-delimited phenotype file"
		phenotype_id: "name: phenotype_id, label: phenotype ID, help: optional string header of the subject ID column (default is first column)"
		trait: "name: trait, label: trait, help: trait/outcome of interest for testing. Note: must be quantitative at this time."
	}
	
	call create_unrelated_ped {
		input: 
			phenofile = phenofile,
			memory = memory
	}

	call create_binary_ped {
		input:
			pedfile = create_unrelated_ped.out_ped,
			memory = memory
	}

	scatter (bin_dosefile in bin_dosefiles) {
		call run_interaction {
			input:
				pedfile = create_unrelated_ped.out_ped,
				bin_pedfile = create_binary_ped.out_ped_bin,
				phenofile = phenofile,
				phenotype_id = phenotype_id,
				trait = trait,
				covars = covars,
				bin_dosefile = bin_dosefile,
				interaction_var = interaction_var,
				memory = memory
		}
	}	

	#output {
	#	File outfile = run_interaction.out
	#}
}
