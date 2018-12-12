# snakemake rules for pulling the immcantation image depending on
# whether docker or singularity is being used

if config['container_type'] == 'docker':
    rule get_immcantation_image:
        """ Pull the immcantation image that is used for
            IgBLAST execution and output parsing
        """
        output:
            '{}/resources/assembly/docker_pull.success'.format(workflow.basedir)
        threads: 1
        params:
            name="container_pull",
            partition=config['partition'],
        resources:
            mem_mb=10000
        shell:
            "docker pull kleinstein/immcantation:2.6.0 && "
            "echo $(date) > {output}"
else:
    # singularity
    rule get_immcantation_image:
        """ Pull the immcantation image that is used for
            IgBLAST execution and output parsing
        """
        output:
            '{}/resources/assembly/immcantation-2.6.0.img'.format(workflow.basedir)
        threads: 1
        params:
            name="container_pull",
            partition=config['partition'],
            singularity_pre_cmd="" if 'singularity_pre_cmd' not in config else config['singularity_pre_cmd']
        resources:
            mem_mb=10000
        shell:
            "{params.singularity_pre_cmd} "
            "cd $(dirname {output}) && "
            "img=$(basename {output}) && "
            "singularity pull --name $img "
            "docker://kleinstein/immcantation:2.6.0"
