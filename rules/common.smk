from glob import glob


def get_r1_r2_fqgz_using_wildcards(wildcards):
    """ Returns R1 and R2 gzipped fastq file paths as a list """

    r1 = glob('{base}/{sample}/*R1*.fastq.gz'.format(base=wildcards['base'],
                                                     sample=wildcards['sample']
                                                     ))

    r2 = glob('{base}/{sample}/*R2*.fastq.gz'.format(base=wildcards['base'],
                                                     sample=wildcards['sample']
                                                     ))

    assert len(r1) == 1
    assert len(r2) == 1

    return [r1[0], r2[0]]
