task create_binary_ped {

	File pedfile
	String bin_pedfile_name = "ped_bin"

	command {
		$MMAP \
			--ped ${pedfile} \
			--compute_binary_relationship_matrix_by_groups \
			--binary_output_filename ${bin_pedfile_name}
	}

	runtime {
		docker: "kwesterman/mmap-workflow:0.1"
		continueOnReturnCode: [0, 1]
	}

	output {
		File out = "${bin_pedfile_name}"
	}
}

task create_binary_gen {

	File dosefile
	Int dosefile_skip_fields
	String bin_genfile_name = "geno_bin"

	command {
		$MMAP \
			--write_binary_genotype_file \
			--csv_input_filename ${dosefile} \
			--num_skip_fields ${dosefile_skip_fields} \
			--binary_output_filename ${bin_genfile_name}
	}

	runtime {
		docker: "kwesterman/mmap-workflow:0.1"
	}
	
	output {
		File out = "${bin_genfile_name}"
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
	}

	output {
		File out = "${trait}.results.mle.pval.slim.csv"
	}
}

workflow run_mmap {

	File dosefile
	Int dosefile_skip_fields = 8
	File phenofile
	String? phenotype_id
	File pedfile
	String trait = "BMI"
	String covars = "SEX"
	String interaction_var = "SEX"

	call create_binary_ped {
		input:
			pedfile = pedfile
	}

	call create_binary_gen {
		input:
			dosefile = dosefile,
			dosefile_skip_fields = dosefile_skip_fields
	}

	call run_interaction {
		input:
			pedfile = pedfile,
			bin_pedfile = create_binary_ped.out,
			phenofile = phenofile,
			phenotype_id = phenotype_id,
			trait = trait,
			covars = covars,
			bin_dosefile = create_binary_gen.out,
			interaction_var = interaction_var
	}

	output {
		File outfile = run_interaction.out
	}
}
