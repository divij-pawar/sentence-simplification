#!/bin/bash

# echo 'Cloning Moses github repository (for tokenization scripts)...'
# git clone https://github.com/moses-smt/mosesdecoder.git

# echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
# git clone https://github.com/rsennrich/subword-nmt.git

# echo 'Cloning Fairseq repository ...'
# git clone https://github.com/facebookresearch/fairseq.git

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

# Calculate the number of lines
total_lines=$(wc -l < "$orig/$src.txt")

# Define split ratios multiplied by 100 to avoid decimals
train_ratio=70
val_ratio=15
test_ratio=15

# Calculate number of lines for each split, dividing by 100 to get actual numbers
train_lines=$((total_lines * train_ratio / 100))
val_lines=$((total_lines * val_ratio / 100))
test_lines=$((total_lines * test_ratio / 100))

# Create train, val, test files
> "$tmp/train.txt"
> "$tmp/val.txt"
> "$tmp/test.txt"

# Iterate over the indices of the arrays (assuming both source and target have the same number of lines)
for ((i=1; i<=total_lines; i++)); do
    src_line=$(sed -n "${i}p" "$orig/int.txt")
    tgt_line=$(sed -n "${i}p" "$orig/ele.txt")

    if [ $i -le $train_lines ]; then
        echo "$src_line ||| $tgt_line" >> "$tmp/train.txt"
    elif [ $i -le $(($train_lines + $val_lines)) ]; then
        echo "$src_line ||| $tgt_line" >> "$tmp/valid.txt"
    else
        echo "$src_line ||| $tgt_line" >> "$tmp/test.txt"
    fi
done

echo "Files created successfully:"


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
echo "Script complete"