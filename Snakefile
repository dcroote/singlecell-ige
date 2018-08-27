from snakemake.utils import validate
import pandas as pd


# load the config file specified in the snakemake command line argument
# --configfile, otherwise load 'config.yaml' in the working directory
if not config:
    configfile: "config.yaml"
validate(config, schema="schemas/config.schema.yaml")

# load and validate samplesheet
samplesheet = pd.read_table(config['samplesheet'])
validate(samplesheet, schema="schemas/samplesheet.schema.yaml")


localrules: all

rule all:
    input:
        'combined_assemblies.tsv',
        'combined_counts.tsv'


include: 'rules/align.smk'
include: 'rules/assemble.smk'
