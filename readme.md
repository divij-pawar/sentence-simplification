# Sentence Simplification with CL using fairseq and BART LLM
## STATUS -> NOT WORKING

### working directory
cd fairseq

### Preprocess data
TEXT=int-ele-sentence-simplification
fairseq-preprocess --source-lang int --target-lang ele \
    --trainpref $TEXT/train --validpref $TEXT/valid --testpref $TEXT/test \
    --destdir data-bin/int-ele-sentence-simplification.tokenized \
    --workers 20 \
    --joined-dictionary 

### Download Bart LLM
wget https://dl.fbaipublicfiles.com/fairseq/models/bart.large.tar.gz
tar -xzvf bart.large.tar.gz
rm bart.large.tar.gz

### Train model on top of bart
CUDA_VISIBLE_DEVICES=0 fairseq-train \
    data-bin/iwslt14.tokenized.de-en \
    --arch bart_large --task translation --share-decoder-input-output-embed \
    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
    --lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
    --dropout 0.3 --weight-decay 0.0001 \
    --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
    --max-tokens 4096 \
    --eval-bleu \
    --eval-bleu-args '{"beam": 5, "max_len_a": 1.2, "max_len_b": 10}' \
    --eval-bleu-detok moses \
    --eval-bleu-remove-bpe \
    --eval-bleu-print-samples \
    --best-checkpoint-metric bleu --maximize-best-checkpoint-metric \
    --share-all-embeddings \
    --restore-file bart.large/model.pt --reset-optimizer --reset-dataloader --reset-meters \