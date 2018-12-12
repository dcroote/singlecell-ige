import os

include: "common.smk"


rule get_genome_fasta_and_gtf:
    """ Get genome and GTF from ensembl """
    output:
        fasta='%s/resources/star/%s.ERCC.fa' % (workflow.basedir, config['fasta_name'][config['species']]),
        gtf='%s/resources/star/%s.ERCC.gtf' % (workflow.basedir, config['fasta_name'][config['species']])
    threads: 1
    params:
        name="wget_files",
        partition=config['partition'],
        fasta_url=config['fasta_url'][config['species']],
        fasta_name=config['fasta_name'][config['species']],
        gtf_url=config['gtf_url'][config['species']],
        gtf_name=config['gtf_name'][config['species']],
        include_ERCCs='true' if config['include_ERCCs'] else 'false'
    resources:
        mem_mb=5000
    shell:
        "fa=resources/star/{params.fasta_name}.fa.gz && "
        "gtf=resources/star/{params.gtf_name}.gtf.gz && "
        "wget {params.fasta_url} -O $fa && "
        "wget {params.gtf_url} -O $gtf && "
        "zcat $fa > {output.fasta} && "
        "zcat $gtf > {output.gtf} && "
        "if [ {params.include_ERCCs} = true ]; then "
        "cat resources/star/ERCC92.fa >> {output.fasta} && "
        "cat resources/star/ERCC92.gtf >> {output.gtf}; fi"


rule star_genome_generate:
    """ Build the STAR genome
        Notes:
        * --genomeSAsparseD is used to reduce genome memory consumption
            during mapping
    """
    input:
        fasta=rules.get_genome_fasta_and_gtf.output.fasta,
        gtf=rules.get_genome_fasta_and_gtf.output.gtf,
        sjadditional='{}/resources/star/IGHC_IGHJ_splices_{}.txt'.format(workflow.basedir,
                                                                         config['species'])
    output:
        '%s/resources/star/star_genome_%s/Genome' % (workflow.basedir,
                                                     config['species'])
    threads: 12
    params:
        name='star_genome_gen',
        partition=config['partition'],
        star_read_len=int(config['read_length']) - 1
    resources:
        mem_mb=60000
    conda:
        os.path.join(workflow.basedir, 'envs/miniconda.yaml')
    shell:
        "genomedir=$(dirname {output}) && "
        "mkdir -p $genomedir && "
        "cd $(dirname $genomedir) && " 
        "STAR --runMode genomeGenerate "
        "--genomeDir $genomedir "
        "--genomeFastaFiles {input.fasta} "
        "--sjdbGTFfile {input.gtf} "
        "--sjdbOverhang {params.star_read_len} "
        "--sjdbFileChrStartEnd {input.sjadditional} "
        "--genomeSAsparseD 2 --runThreadN {threads}"


rule star:
    """ Map reads to genome using STAR
        Notes:
        * Expects gzipped fastqs
        * Output is unsorted to reduce htseq memory consumption
            and avoid mates being "too far" from one another per HTSeq
            when SortedByCoordinate
        * --twopassMode for better splice alignments
        * --outSAMmapqUnique 60 for any downstream variant analysis
        * --outFilterMismatchNmax disabled by high value
        * --outFilterMismatchNoverReadLmax set higher to account for
            somatic hypermutation
    """
    input:
        rules.star_genome_generate.output,
        get_r1_r2_fqgz_using_wildcards
    output:
        '{base}/{sample}/star/Aligned.out.bam'
    threads: 6
    params:
        name='star',
        partition=config['partition']
    resources:
        mem_mb=30000
    conda:
        os.path.join(workflow.basedir, 'envs/miniconda.yaml')
    shell:  "wdir=$(dirname {output}) && "
            "echo $wdir && "
            "mkdir -p $wdir && "
            "STAR "
            "--genomeDir $(dirname {input[0]}) "
            "--readFilesIn {input[1]} {input[2]} "
            "--readFilesCommand gunzip -c "
            "--outSAMmapqUnique 60 "
            "--outFilterMismatchNmax 999 "
            "--outFilterMismatchNoverReadLmax 0.1 "
            "--twopassMode Basic "
            "--runThreadN {threads} "
            "--outSAMtype BAM Unsorted "
            "--outFileNamePrefix $wdir/"


rule htseq:
    """ Count reads mapping to features using htseq
        Notes:
        * expects STAR bam sorted by name (-r name)
        *  -m intersection-nonempty: if a read overlaps 2 genes,
            will assign to the gene with more overlap
        * scRNA-seq data is not stranded (-s no)
    """
    input:
        bam=rules.star.output,
        gtf=rules.get_genome_fasta_and_gtf.output.gtf,
    output:
        '{base}/{sample}/htseq/htseq.tsv'
    threads: 1
    params:
        name='htseq',
        partition=config['partition']
    resources:
        mem_mb=5000
    conda:
        os.path.join(workflow.basedir, 'envs/miniconda.yaml')
    shell: "mkdir -p $(dirname {output}) && "
           "htseq-count -s no -r name -f bam -m intersection-nonempty "
           "{input.bam} {input.gtf} > {output}"


rule combine_counts:
    """ Join htseq count files from all samples into a single table """
    input:
        expand('{base}/{sample}/htseq/htseq.tsv',
                zip,
                base=samplesheet.base.values.tolist(),
                sample=samplesheet.samplename.values.tolist())
    output:
        'combined_counts.tsv'
    threads: 1
    params:
        name="combine_counts",
        partition=config['partition'],
        scripts_dir=os.path.join(workflow.basedir, 'scripts')
    resources:
        mem_mb=5000
    conda:
        os.path.join(workflow.basedir, 'envs/miniconda.yaml')
    shell:
        "python {params.scripts_dir}/combine_counts.py {config[samplesheet]} {output}"

