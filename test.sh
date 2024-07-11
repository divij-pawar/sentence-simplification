echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
# git clone https://github.com/rsennrich/subword-nmt.git

src=int
tgt=ele
lang=int-ele
prep=prep
tmp=prep/tmp
orig=orig
BPEROOT=subword-nmt/subword_nmt
BPE_TOKENS=10000


TRAIN=$orig/train.int-ele
BPE_CODE=$prep/code
rm -f $TRAIN
cat $tmp/ELE-INT.txt >> $TRAIN
cat $tmp/train.txt >> $TRAIN

echo "learn_bpe.py on ${TRAIN}..."
python3 $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $TRAIN > $BPE_CODE
for f in train.txt valid.txt test.txt; do
        echo "apply_bpe.py to ${f}..."
        python3 $BPEROOT/apply_bpe.py -c $BPE_CODE < $tmp/$f > $prep/$f
    done