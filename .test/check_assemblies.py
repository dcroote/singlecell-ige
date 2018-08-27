import pandas as pd
import sys


def main(infile):
    """ Simple checks for the .test directory assembly output table """

    df = pd.read_table(infile)

    # 2 cells, each with a heavy and light
    assert df.shape[0] == 4

    assert df.groupby('SAMPLENAME').SEQUENCE_ID.apply(
        lambda x: \
        x.shape[0] ==2 and \
        x.str.contains("heavy").sum() == 1 and \
        x.str.contains("light").sum() == 1
    ).all()

    # all variable regions should be functional
    assert (df.FUNCTIONAL == 'T').all()


if __name__ == "__main__":
    main(sys.argv[1])
