import os
import pandas as pd
import argparse


def parse_args():

    parser = argparse.ArgumentParser()

    parser.add_argument('infile_samplesheet')
    parser.add_argument('outfile')

    return parser.parse_args()


def main():
    """ Combines individual htseq-count files into a single table. """

    args = parse_args()

    df = pd.read_table(args.infile_samplesheet)

    counts = []
    for row in df.itertuples():
        infile = os.path.join(row.base, row.samplename, 'htseq',
                              'htseq.tsv')

        try:
            tmpdf = pd.read_table(infile, header=None,
                                  names=['gene', row.samplename])
        except pd.errors.EmptyDataError:
            continue

        # set gene as index for concatenation later
        tmpdf.set_index('gene', inplace=True)

        counts.append(tmpdf)

    outdf = pd.concat(counts, axis=1)

    outdf.to_csv(args.outfile, sep='\t')


if __name__ == "__main__":
    main()
