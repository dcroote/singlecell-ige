# shell script for creating the constant region database used for assembly
# constant region calling

makeblastdb -parse_seqids -dbtype nucl -in $1 -out $(basename $1)
