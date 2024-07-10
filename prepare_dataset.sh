#echo 'Cloning Moses github repository (for tokenization scripts)...'
#git clone https://github.com/moses-smt/mosesdecoder.git

#echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
#git clone https://github.com/rsennrich/subword-nmt.git

SCRIPTS=mosesdecoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
LC=$SCRIPTS/tokenizer/lowercase.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
BPEROOT=subword-nmt/subword_nmt
BPE_TOKENS=10000

if [ ! -d "$SCRIPTS" ]; then
    echo "Please set SCRIPTS variable correctly to point to Moses scripts."
    exit
fi

src=int
tgt=ele
lang=int-ele
prep=prep
tmp=prep/tmp
orig=orig

mkdir -p $tmp $prep


echo "pre-processing train data..."
for l in $src $tgt; do
    f=$l
    tok=tok.$l

    cat $orig/$f.txt | \
    grep -v '<url>' | \
    grep -v '<talkid>' | \
    grep -v '<keywords>' | \
    sed -e 's/<title>//g' | \
    sed -e 's/<\/title>//g' | \
    sed -e 's/<description>//g' | \
    sed -e 's/<\/description>//g' | \
    perl $TOKENIZER -threads 8 -l en > $tmp/$tok
    echo ""
done
perl $CLEAN -ratio 1.5 $tmp/tok $src $tgt $tmp/clean 1 50
for l in $src $tgt; do
    perl $LC < $tmp/clean.$l > $tmp/$l
done

echo "pre-processing valid/test data..."
for l in $src $tgt; do
	# Process each file in the specified directory
	for o in $orig/*.txt; do
	fname=${o##*/}
        f=$tmp/${fname%.*}.processed.txt
        echo "Processing $o -> $f"
        cat $o | \
            sed -e "s/\’/\'/g" | \
            perl $TOKENIZER -threads 8 -l $l | \
            perl $LC > $f

        echo "Finished processing $o"
    done
done
echo "Pre-processing completed."
