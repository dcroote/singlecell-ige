import os
import pandas as pd
import argparse


def parse_args():

    parser = argparse.ArgumentParser()

    parser.add_argument('infile_samplesheet')
    parser.add_argument('outfile')

    return parser.parse_args()


def main():
    """ Combines parsed assemblies into a single table. """

    args = parse_args()

    df = pd.read_table(args.infile_samplesheet)

    assemblies = []
    for row in df.itertuples():
        infile = os.path.join(row.base, row.samplename, 'basic',
                              'igblast_db-pass_const-merge.tsv')

        try:
            tmpdf = pd.read_table(infile)
        except pd.errors.EmptyDataError:
            continue

        tmpdf['SAMPLENAME'] = row.samplename

        assemblies.append(tmpdf)

    outdf = pd.concat(assemblies)

    outdf.to_csv(args.outfile, sep='\t')


if __name__ == "__main__":
    main()
