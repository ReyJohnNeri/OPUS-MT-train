# -*-makefile-*-

#------------------------------------------------------------------------
# translate and evaluate all test sets in testsets/
#------------------------------------------------------------------------

## testset dir for all test sets in this language pair
## and all trokenized test sets that can be found in that directory
TESTSET_HOME    = ${REPOHOME}testsets
TESTSET_DIR     = ${TESTSET_HOME}/${SRC}-${TRG}
TESTSETS        = $(sort $(patsubst ${TESTSET_DIR}/%.${SRCEXT}.gz,%,${wildcard ${TESTSET_DIR}/*.${SRCEXT}.gz}))
TESTSETS_PRESRC = $(patsubst %,${TESTSET_DIR}/%.${SRCEXT}.${PRE}.gz,${TESTSETS})
TESTSETS_PRETRG = $(patsubst %,${TESTSET_DIR}/%.${TRGEXT}.${PRE}.gz,${TESTSETS})

OPUSMT_TESTSETS_GITRAW := https://raw.githubusercontent.com/Helsinki-NLP/OPUS-MT-testsets/master
OPUSMT_TESTSETS_TSV    := ${OPUSMT_TESTSETS_GITRAW}/testsets.tsv

## eval all available test sets
## - fetch test sets from OPUS-MT-testsets
## - add language labels if necessary
## - start translation and evaluate
eval-testsets-all:
	rm -f $@.tsv
	wget -O $@.tsv ${OPUSMT_TESTSETS_TSV}
	for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    for n in `grep "^$$s	$$t	" $@.tsv | cut -f3`; do \
	      p=`grep "^$$s	$$t	$$n	" $@.tsv | cut -f5,6,7,8`; \
	      l=`echo "$$p" | cut -f2`; \
	      i=`echo "$$p" | cut -f3`; \
	      o=`echo "$$p" | cut -f4`; \
	      echo "get $$i and $$o"; \
	      rm -f ${WORKDIR}/test/$$n-$$s$$t.src ${WORKDIR}/test/$$n-$$s$$t.trg; \
	      if [ "${USE_TARGET_LABELS}" == "1" ]; then \
	         if [ "$$l" == "" ]; then \
	           echo "add language labels to $$i"; \
	           wget -O ${WORKDIR}/test/$$n-$$s$$t.srcraw ${OPUSMT_TESTSETS_GITRAW}/$$i; \
	           sed "s/^/>>$${t}<< /" < ${WORKDIR}/test/$$n-$$s$$t.srcraw > ${WORKDIR}/test/$$n-$$s$$t.src; \
	           rm -f ${WORKDIR}/test/$$n-$$s$$t.srcraw; \
	         else \
	           echo "add language labels from $$l"; \
	           wget -O ${WORKDIR}/test/$$n-$$s$$t.srcraw ${OPUSMT_TESTSETS_GITRAW}/$$i; \
	           wget -O ${WORKDIR}/test/$$n-$$s$$t.langids ${OPUSMT_TESTSETS_GITRAW}/$$l; \
		   sed 's/^/>>/;s/$$/<</' < ${WORKDIR}/test/$$n-$$s$$t.langids > ${WORKDIR}/test/$$n-$$s$$t.labels; \
	           paste -d ' ' ${WORKDIR}/test/$$n-$$s$$t.labels ${WORKDIR}/test/$$n-$$s$$t.srcraw \
	           | sed 's/^ />>$${t}<< /' > ${WORKDIR}/test/$$n-$$s$$t.src; \
	           rm -f ${WORKDIR}/test/$$n-$$s$$t.srcraw ${WORKDIR}/test/$$n-$$s$$t.langids ${WORKDIR}/test/$$n-$$s$$t.labels; \
	         fi \
	      fi; \
	      wget -O ${WORKDIR}/test/$$n-$$s$$t.trg ${OPUSMT_TESTSETS_GITRAW}/$$o; \
	      ${MAKE} TESTSET=$$n TESTSET_NAME=$$n-$$s$$t SRC=$$s TRG=$$t SKIP_CREATE_TESTSET=1 compare; \
	      rm -f ${WORKDIR}/test/$$n-$$s$$t.src ${WORKDIR}/test/$$n-$$s$$t.trg; \
	    done \
	  done \
	done


DO_EVAL_LANGPAIRS     := $(patsubst %,eval-testsets_%,${LANGPAIRS})
DO_EVAL_LANGPAIRS_ENG := $(filter %-eng eng-%,${DO_EVAL_LANGPAIRS})

eval-testsets: ${DO_EVAL_LANGPAIRS}
eval-english-testsets: ${DO_EVAL_LANGPAIRS_ENG}

eval-testsets_%:
	rm -f $@.tsv
	wget -O $@.tsv ${OPUSMT_TESTSETS_TSV}
	( s=$(firstword $(subst -, ,$(patsubst eval-testsets_%,%,$@))); \
	  t=$(lastword $(subst -, ,$(patsubst eval-testsets_%,%,$@))); \
	  for n in `grep "^$$s	$$t	" $@.tsv | cut -f3`; do \
	      p=`grep "^$$s	$$t	$$n	" $@.tsv | cut -f5,6,7,8`; \
	      l=`echo "$$p" | cut -f2`; \
	      i=`echo "$$p" | cut -f3`; \
	      o=`echo "$$p" | cut -f4`; \
	      echo "get $$i and $$o"; \
	      rm -f ${WORKDIR}/test/$$n-$$s$$t.src ${WORKDIR}/test/$$n-$$s$$t.trg; \
	      if [ "${USE_TARGET_LABELS}" == "1" ]; then \
	         if [ "$$l" == "" ]; then \
	           echo "add language labels to $$i"; \
	           wget -O ${WORKDIR}/test/$$n-$$s$$t.srcraw ${OPUSMT_TESTSETS_GITRAW}/$$i; \
	           sed "s/^/>>$${t}<< /" < ${WORKDIR}/test/$$n-$$s$$t.srcraw > ${WORKDIR}/test/$$n-$$s$$t.src; \
	           rm -f ${WORKDIR}/test/$$n-$$s$$t.srcraw; \
	         else \
	           echo "add language labels from $$l"; \
	           wget -O ${WORKDIR}/test/$$n-$$s$$t.srcraw ${OPUSMT_TESTSETS_GITRAW}/$$i; \
	           wget -O ${WORKDIR}/test/$$n-$$s$$t.langids ${OPUSMT_TESTSETS_GITRAW}/$$l; \
		   sed 's/^/>>/;s/$$/<</' < ${WORKDIR}/test/$$n-$$s$$t.langids > ${WORKDIR}/test/$$n-$$s$$t.labels; \
	           paste -d ' ' ${WORKDIR}/test/$$n-$$s$$t.labels ${WORKDIR}/test/$$n-$$s$$t.srcraw \
	           | sed 's/^ />>$${t}<< /' > ${WORKDIR}/test/$$n-$$s$$t.src; \
	           rm -f ${WORKDIR}/test/$$n-$$s$$t.srcraw ${WORKDIR}/test/$$n-$$s$$t.langids ${WORKDIR}/test/$$n-$$s$$t.labels; \
	         fi \
	      fi; \
	      wget -O ${WORKDIR}/test/$$n-$$s$$t.trg ${OPUSMT_TESTSETS_GITRAW}/$$o; \
	      ${MAKE} TESTSET=$$n TESTSET_NAME=$$n-$$s$$t SRC=$$s TRG=$$t SKIP_CREATE_TESTSET=1 compare; \
	      rm -f ${WORKDIR}/test/$$n-$$s$$t.src ${WORKDIR}/test/$$n-$$s$$t.trg; \
	  done )



## eval all available test sets
eval-testsets-old:
	for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    if [ -e ${TESTSET_HOME}/$$s-$$t ]; then \
	      ${MAKE} SRC=$$s TRG=$$t SKIP_CREATE_TESTSET=1 compare-testsets-langpair; \
	    fi \
	  done \
	done

%-testsets-langpair: ${TESTSETS_PRESRC} ${TESTSETS_PRETRG}
	@echo "testsets: ${TESTSET_DIR}/*.${SRCEXT}.gz"
	for t in ${TESTSETS}; do \
	  ${MAKE} TESTSET=$$t TESTSET_NAME=$$t-${SRC}${TRG} ${@:-testsets-langpair=}; \
	done



#------------------------------------------------------------------------
# translate with an ensemble of several models
#------------------------------------------------------------------------

ENSEMBLE = ${wildcard ${WORKDIR}/${MODEL}.${MODELTYPE}.model*.npz.best-perplexity.npz}

${WORKDIR}/${TESTSET_NAME}.${MODEL}${NR}.${MODELTYPE}.ensemble.${SRC}.${TRG}: ${TEST_SRC}.${PRE_SRC} ${ENSEMBLE}
	mkdir -p ${dir $@}
	grep . $< > $@.input
	${LOAD_ENV} && ${MARIAN_DECODER} -i $@.input \
		--models ${ENSEMBLE} \
		--vocabs ${MODEL_SRCVOCAB} ${MODEL_TRGVOCAB} \
		${MARIAN_DECODER_FLAGS} > $@.output
ifneq ($(findstring spm,${PRE_TRG}),)
	sed 's/ //g;s/▁/ /g' < $@.output | sed 's/^ *//;s/ *$$//' > $@
else
	sed 's/\@\@ //g;s/ \@\@//g;s/ \@\-\@ /-/g' < $@.output |\
	$(TOKENIZER)/detokenizer.perl -l ${TRG} > $@
endif
	rm -f $@.input $@.output


#------------------------------------------------------------------------
# translate, evaluate and generate a file 
# for comparing system to reference translations
#------------------------------------------------------------------------

${WORKDIR}/${TESTSET_NAME}.${MODEL}${NR}.${MODELTYPE}.${SRC}.${TRG}: ${TEST_SRC}.${PRE_SRC} ${MODEL_FINAL}
	mkdir -p ${dir $@}
	grep . $< > $@.input
	${LOAD_ENV} && ${MARIAN_DECODER} -i $@.input \
		-c ${word 2,$^}.decoder.yml \
		${MARIAN_DECODER_FLAGS} > $@.output
ifneq ($(findstring spm,${PRE_TRG}),)
	sed 's/ //g;s/▁/ /g' < $@.output | sed 's/^ *//;s/ *$$//' > $@
else
	sed 's/\@\@ //g;s/ \@\@//g;s/ \@\-\@ /-/g' < $@.output |\
	$(TOKENIZER)/detokenizer.perl -l ${TRG} > $@
endif
	rm -f $@.input $@.output

## adjust tokenisation to non-space-separated languages
## TODO: is it correct to simply use 'zh' or should we use 'intl'?
ifneq ($(filter zh zho jp jpn cmn,${TRGLANGS}),)
  SACREBLEU_PARAMS = --tokenize zh
endif

## simple hack that makes chrF scores compatible with previous version
## of sacrebleu (now: score in percentages)
## --> this breaks easily if the score < 10 or = 100

%.eval: % ${TEST_TRG}
	paste ${TEST_SRC}.${PRE_SRC} ${TEST_TRG} | grep $$'.\t' | cut -f2 > $@.ref
	cat $< | sacrebleu -f text ${SACREBLEU_PARAMS} $@.ref > $@
	cat $< | sacrebleu -f text ${SACREBLEU_PARAMS} --metrics=chrf --width=3 $@.ref |\
	sed 's/\([0-9][0-9]\)\.\([0-9]*\)$$/0.\1\2/'         >> $@
	rm -f $@.ref


%.compare: %.eval
	grep . ${TEST_SRC} > $@.1
	grep . ${TEST_TRG} > $@.2
	grep . ${<:.eval=} > $@.3
	paste -d "\n" $@.1 $@.2 $@.3 |\
	sed 	-e "s/&apos;/'/g" \
		-e 's/&quot;/"/g' \
		-e 's/&lt;/</g' \
		-e 's/&gt;/>/g' \
		-e 's/&amp;/&/g' |\
	sed 'n;n;G;' > $@
	rm -f $@.1 $@.2 $@.3



##--------------------------------------------------------------------------------------------
## some tools for reporting current scores in the work directory
##
##   make print-bleu-scores ......... print all bleu scores for all tested benchmarks and models
##   make compare-bleu-scores ....... compare scores with best BLEU scores in leaderboard
##   make print-improved-models ..... print model scores that are better than best reported score
##   make print-decreased-models .... print model scores that are worse than best reported score
##--------------------------------------------------------------------------------------------

print-bleu-score-table:
#	@grep BLEU ${WORKHOME}/*/*.eval |
	@find ${WORKHOME}/ -name '*.eval' | xargs grep BLEU |\
	perl -pe 's#^${WORKHOME}/([^/]*)/([^\.]+)\.(.*?-.*?\.)?([^\.]+\.[^\.]+\.[^\.]+)\.([^\.]+)\.([^\.]+)\.eval:.*? = ([0-9\.]+) .*$$#$$5-$$6\t$$7\t$$2\t$$1\t$$4#' |\
	perl -pe '@a=split(/\t/);if($$a[0]=~/multi/){$$a[0]=$$a[3];};$$_=join("\t",@a);' |\
	sort -k3,3 -k1,1 -k2,2nr

print-bleu-scores:
	@make -s print-bleu-score-table |\
	perl -e 'while (<>){@a=split(/\t/);printf "%15s  %5.2f  %-25s  %-15s  %s",@a;}'



LEADERBOARD_DIR = ${REPOHOME}scores

## manipulating test set names is really messy
## - need to remove language ID pairs
## - could be different variants (2-lettter codes, 3-letter codes)
## - newstest sometimes has additional langpair-IDs in their names

compare-bleu-score-table:
	@find ${WORKHOME}/ -name '*.eval' | xargs grep BLEU |\
	perl -pe 's#^${WORKHOME}/([^/]*)/([^\.]+)\.(.*?-.*?\.)?([^\.]+\.[^\.]+\.[^\.]+)\.([^\.]+)\.([^\.]+)\.eval:.*? = ([0-9\.]+) .*$$#$$5-$$6\t$$7\t$$2\t$$1\t$$4#' |\
	grep -v '^[a-z\-]*multi' |\
	perl -pe '@a=split(/\t/);if($$a[0]=~/multi/){$$a[0]=$$a[3];};$$_=join("\t",@a);' |\
	perl -pe '@a=split(/\t/);$$a[2]=lc($$a[2]);$$a[2]=~s/^(.*)\-[a-z]{4}$$/$$1/;$$a[2]=~s/^(.*)\-[a-z]{6}$$/$$1/;$$a[2]=~s/^(news.*)\-[a-z]{4}/$$1/;if (-e "${LEADERBOARD_DIR}/$$a[0]/$$a[2]/bleu-scores.txt"){$$b=`head -1 ${LEADERBOARD_DIR}/$$a[0]/$$a[2]/bleu-scores.txt | cut -f1`;$$b+=0;}else{$$b=0;}$$d=$$a[1]-$$b;splice(@a,2,0,$$b,$$d);$$_=join("\t",@a);' |\
	sort -k5,5 -k1,1 -k2,2nr

compare-bleu-scores:
	@make -s compare-bleu-score-table |\
	perl -e 'printf "%15s  %5s  %5s  %6s  %-25s  %-15s  %s","langpair","BLEU","best","diff","testset","dir","model\n";while (<>){@a=split(/\t/);printf "%15s  %5.2f  %5.2f  %6.2f  %-25s  %-15s  %s",@a;}'

print-improved-models:
	@make -s compare-bleu-scores |\
	grep -v ' 0.00  [a-z]' | grep -v ' -[0-9]'

print-decreased-models:
	@make -s compare-bleu-scores |\
	grep ' -[0-9]'


## compare BLEU scores for the current model

compare-model-bleu-score-table:
	@grep BLEU ${WORKDIR}/*.eval |\
	perl -pe 's#^${WORKHOME}/([^/]*)/([^\.]+)\.(.*?-.*?\.)?([^\.]+\.[^\.]+\.[^\.]+)\.([^\.]+)\.([^\.]+)\.eval:.*? = ([0-9\.]+) .*$$#$$5-$$6\t$$7\t$$2\t$$1\t$$4#' |\
	grep -v '^[a-z\-]*multi' |\
	perl -pe '@a=split(/\t/);if($$a[0]=~/multi/){$$a[0]=$$a[3];};$$_=join("\t",@a);' |\
	perl -pe '@a=split(/\t/);$$a[2]=lc($$a[2]);$$a[2]=~s/^(.*)\-[a-z]{4}$$/$$1/;$$a[2]=~s/^(.*)\-[a-z]{6}$$/$$1/;$$a[2]=~s/^(news.*)\-[a-z]{4}$$/$$1/;if (-e "${LEADERBOARD_DIR}/$$a[0]/$$a[2]/bleu-scores.txt"){$$b=`head -1 ${LEADERBOARD_DIR}/$$a[0]/$$a[2]/bleu-scores.txt | cut -f1`;$$b+=0;}else{$$b=0;}$$d=$$a[1]-$$b;splice(@a,2,0,$$b,$$d);$$_=join("\t",@a);' |\
	sort -k5,5 -k1,1 -k2,2nr

compare-model-bleu-scores:
	make -s compare-model-bleu-score-table |\
	perl -e 'printf "%15s  %5s  %5s  %6s  %-25s  %-15s  %s","langpair","BLEU","best","diff","testset","dir","model\n";while (<>){@a=split(/\t/);printf "%15s  %5.2f  %5.2f  %6.2f  %-25s  %-15s  %s",@a;}'

print-improved-bleu:
	@make -s compare-model-bleu-scores |\
	grep -v ' 0.00' | grep -v ' -[0-9]'

print-decreased-bleu:
	@make -s compare-model-bleu-scores |\
	grep ' -[0-9]'
