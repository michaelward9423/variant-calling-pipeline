
# Snakemake pipeline for variant calling

rule trim:
  output:
    fq_out1   = "trimmed_fastq/{sample}_1.trimmed.fastq",
    fq_out1un = "trimmed_fastq/{sample}_1un.trimmed.fastq",
    fq_out2   = "trimmed_fastq/{sample}_2.trimmed.fastq",
    fq_out2un = "trimmed_fastq/{sample}_2un.trimmed.fastq"
  input:
    fq_in1 = "untrimmed_fastq/{sample}_1.fastq.gz",
    fq_in2 = "untrimmed_fastq/{sample}_2.fastq.gz"
  shell:
    """
      trimmomatic PE -threads 1 \
        {input.fq_in1} {input.fq_in2} \
        {output.fq_out1} {output.fq_out1un} \
        {output.fq_out2} {output.fq_out2un} \
        SLIDINGWINDOW:4:20 \
        MINLEN:25 \
        ILLUMINACLIP:untrimmed_fastq/NexteraPE-PE.fa:2:40:15
    """

rule fastqc:
  output:
    html = "qc/{sample}_fastqc.html",
    zip = "qc/{sample}_fastqc.zip"
  input:
    "untrimmed_fastq/{sample}.fastq.gz"
  shell:
    """
      fastqc -o -qc {input}
    """

rule bwa_mem:
  output:
    "results/sam/{sample}.aligned.sam"
  input:
    ref   = "data/ecoli_rel606.fasta",
    read1 = "trimmed_fastq_small/{sample}_1.trim.sub.fastq",
    read2 = "trimmed_fastq_small/{sample}_2.trim.sub.fastq"
  shell:
    """
      bwa mem {input.ref} \
        {input.read1} {input.read2} > {output}
    """
rule sam_view:
  output:
    "results/bam/{sample}.aligned.bam"
  input:
    "results/sam/{sample}.aligned.sam"
  shell:
    "samtools view -S -b {input} > {output}"

rule sam_sort:
  output:
    "results/bam/{sample}.aligned.sorted.bam"
  input:
    "results/bam/{sample}.aligned.bam"
  shell:
    "samtools sort -o {output} {input}"

rule mpileup:
  output:
    "results/bcf/{sample}_raw.bcf"
  input:
    fasta = "data/ecoli_rel606.fasta",
    bam   = "results/bam/{sample}.aligned.sorted.bam"
  shell:
    "bcftools mpileup -O b -o {output} -f {input.fasta} {input.bam}"
