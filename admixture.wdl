version 1.0

workflow AdmixtureTest {
  input {
    File bed
    File bim
    File fam
    Int n_ancestral_populations
    Boolean merge_with_1kg = false
  }

  if(merge_with_1kg) {
    call MergeRefPanel {
      input:
        bed1 = bed,
        bim1 = bim,
        fam1 = fam,
        bed2 = "gs://fc-ed4d3592-357f-4e9f-9228-67a5881f55ac/1kg/group2.bed",
        bim2 = "gs://fc-ed4d3592-357f-4e9f-9228-67a5881f55ac/1kg/group2.bim",
        fam2 = "gs://fc-ed4d3592-357f-4e9f-9228-67a5881f55ac/1kg/group2.fam",
        output_prefix = 'merged'
        
    }
  }

  call Admixture_t {
    input:
      bed = select_first([MergeRefPanel.merged_bed, bed]),
      bim = select_first([MergeRefPanel.merged_bim, bim]),
      fam = select_first([MergeRefPanel.merged_fam, fam]),
      n_ancestral_populations = n_ancestral_populations
  }

}

task Admixture_t {
  input {
    File bed
    File bim
    File fam
    Int n_ancestral_populations
    Boolean cv = false
    Int mem = 32
    Int n_cpus = 4
  }

  Int disk_size = ceil(1.5*(size(bed, "GB") + size(bim, "GB") + size(fam, "GB")))
  String basename = basename(bed, ".bed")

  command <<<

    /admixture_linux-1.3.0/admixture ~{if (cv) then "--cv" else ""} ~{bed} ~{n_ancestral_populations} -j~{n_cpus}
  >>>

  runtime {
    docker: "us.gcr.io/broad-dsde-methods/admixture_docker:v1.0.0"
    disks: "local-disk " + disk_size + " HDD"
    memory: mem + " GB"
    cpu: n_cpus
  }

  output {
    File ancestry_fractions = "~{basename}.~{n_ancestral_populations}.Q"
    File allele_frequencies = "~{basename}.~{n_ancestral_populations}.P"
  }
}


task MergeRefPanel {
    input {
        File bed1
        File bim1
        File fam1
        File bed2
        File bim2 
        File fam2
        String output_prefix
        Int mem = 4
    }
    Int disk_size1 = ceil(1.5*(size(bed1, "GB") + size(bim1, "GB") + size(fam1, "GB")))
    Int disk_size_all = disk_size1 + ceil(1.5*(size(bed2, "GB") + size(bim2, "GB") + size(fam2, "GB")))
    command <<<
        plink --bed ~{bed1} --bim ~{bim1} --fam ~{fam1} --bmerge ~{bed2} ~{bim2} ~{fam2} --make-bed --out ~{output_prefix} --maf 0.01
    >>>

    output{
        File merged_bed = "~{output_prefix}.bed"
        File merged_bim = "~{output_prefix}.bim"
        File merged_fam = "~{output_prefix}.fam"
    }
    runtime {
    docker: "roohy7/plink-1.9"
    disks: "local-disk " + disk_size_all + " HDD"
    memory: mem + " GB"
  }
}

task LDPrune {
  input {
    File bed_file
    File bim_file
    File fam_file
    Float min_r
    Int window_size
    Int step_size
    String output_prefix
    Int mem = 4
  }
  Int disk_size = ceil(1.5*(size(bed_file, "GB") + size(bim_file, "GB") + size(fam_file, "GB")))
  command <<<
    plink --bed ~{bed_file} --bim ~{bim_file} --fam ~{fam_file} --indep-pairwise ~{window_size} ~{step_size} ~{min_r} --out ~{output_prefix}
    plink --bed ~{bed_file} --bim ~{bim_file} --fam ~{fam_file} --extract ~{output_prefix}.prune.in --make-bed --out ~{output_prefix}
    rm ~{output_prefix}.prune.*
  >>>

  output{
    File pruned_bed = '~{output_prefix}.bed'
    File pruned_bim = '~{output_prefix}.bim'
    File pruned_fam = '~{output_prefix}.fam'
  }
  runtime {
    docker: "roohy7/plink-1.9"
    disks: "local-disk " + disk_size + " HDD"
    memory: mem + " GB"
  }
}