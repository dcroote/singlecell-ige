import pandas as pd
import argparse


def parse_args():

    parser = argparse.ArgumentParser()

    parser.add_argument('infile_changeo')
    parser.add_argument('infile_constant_blast')
    parser.add_argument('outfile')

    return parser.parse_args()


def best_scoring_const_region_hits(frame):
    """ Returns dataframe subset to the max scoring row
        for each SEQUENCE_ID
    """

    return frame.loc[frame.groupby('SEQUENCE_ID').C_SCORE.idxmax()]


def main():
    """ Merges constant region assembly blast results with immcantation
        changeo-igblast table
    """

    args = parse_args()

    # load igblast output parsed by change-o
    try:
        changeodf = pd.read_table(args.infile_changeo)
    except pd.errors.EmptyDataError:
        # touch empty file if no assemblies
        with open(args.outfile, 'w'):
            pass
        return 0

    # load constant blast
    iso_cols = ['SEQUENCE_ID', 'C_CALL_LONG', 'C_LEN', 'C_IDENT',
                'C_MISMATCHES', 'C_GAPS', 'C_START', 'C_END', 'C_SCORE',
                'C_EVAL']
    try:
        isodf = pd.read_table(args.infile_constant_blast, names=iso_cols)
    except pd.errors.EmptyDataError:
        # if we have no constant region blast results, write out
        # (missing columns will not be an issue later when
        # we concat all cells together)
        changeodf.to_csv(args.outfile, index=False, sep='\t')
        return 0

    # trim long C_CALL to short name
    # e.g. L00022|IGHE*02|Homo_sapiens|F|CH1+CH2+C --> IGHE*02
    isodf['C_CALL'] = isodf.C_CALL_LONG.str.split('|', expand=True)[1]

    # desired columns to save from the constant blast results
    out_cols = ['SEQUENCE_ID', 'C_CALL', 'C_LEN', 'C_IDENT', 'C_MISMATCHES',
                'C_GAPS', 'C_SCORE']

    # takes the highest scoring constant region for each SEQUENCE_ID
    isodf_top_hits = best_scoring_const_region_hits(isodf)

    outdf = changeodf.merge(isodf_top_hits[out_cols])

    outdf.to_csv(args.outfile, index=False, sep='\t')


if __name__ == "__main__":
    main()
