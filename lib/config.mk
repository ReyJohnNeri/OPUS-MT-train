# -*-makefile-*-
#
# model configurations
#


# SRCLANGS = da no sv
# TRGLANGS = fi

SRCLANGS = sv
TRGLANGS = fi

SRC ?= ${firstword ${SRCLANGS}}
TRG ?= ${lastword ${TRGLANGS}}


# sorted languages and langpair used to match resources in OPUS
SORTLANGS   = $(sort ${SRC} ${TRG})
SPACE       = $(empty) $(empty)
LANGPAIR    = ${firstword ${SORTLANGS}}-${lastword ${SORTLANGS}}
LANGSRCSTR  = ${subst ${SPACE},+,$(SRCLANGS)}
LANGTRGSTR  = ${subst ${SPACE},+,$(TRGLANGS)}
LANGPAIRSTR = ${LANGSRCSTR}-${LANGTRGSTR}


## for monolingual things
LANGS ?= ${SRCLANGS}
LANGID ?= ${firstword ${LANGS}}
LANGSTR ?= ${subst ${SPACE},+,$(LANGS)}


## for same language pairs: add numeric extension
ifeq (${SRC},$(TRG))
  SRCEXT = ${SRC}1
  TRGEXT = ${SRC}2
else
  SRCEXT = ${SRC}
  TRGEXT = ${TRG}
endif

## set additional argument options for opus_read (if it is used)
## e.g. OPUSREAD_ARGS = -a certainty -tr 0.3
OPUSREAD_ARGS = 

## all of OPUS (NEW: don't require MOSES format)
# OPUSCORPORA  = ${patsubst %/latest/moses/${LANGPAIR}.txt.zip,%,\
#		${patsubst ${OPUSHOME}/%,%,\
#		${shell ls ${OPUSHOME}/*/latest/moses/${LANGPAIR}.txt.zip}}}
OPUSCORPORA  = ${patsubst %/latest/xml/${LANGPAIR}.xml.gz,%,\
		${patsubst ${OPUSHOME}/%,%,\
		${shell ls ${OPUSHOME}/*/latest/xml/${LANGPAIR}.xml.gz}}}

## monolingual data
OPUSMONOCORPORA  = ${patsubst %/latest/mono/${LANGID}.txt.gz,%,\
		${patsubst ${OPUSHOME}/%,%,\
		${shell ls ${OPUSHOME}/*/latest/mono/${LANGID}.txt.gz}}}


ALL_LANG_PAIRS = ${shell ls ${WORKHOME} | grep -- '-' | grep -v old}
ALL_BILINGUAL_MODELS = ${shell echo '${ALL_LANG_PAIRS}' | tr ' ' "\n" |  grep -v -- '\+'}
ALL_MULTILINGUAL_MODELS = ${shell echo '${ALL_LANG_PAIRS}' | tr ' ' "\n" | grep -- '\+'}

# ALL_BILINGUAL_MODELS = ${shell ls ${WORKHOME} | grep -- '-' | grep -v old | grep -v -- '\+'}
# ALL_MULTILINGUAL_MODELS = ${shell ls ${WORKHOME} | grep -- '-' | grep -v old | grep -- '\+'}


## size of dev data, test data and BPE merge operations
## NEW default size = 2500 (keep more for training for small languages)

DEVSIZE     = 2500
TESTSIZE    = 2500

## NEW: significantly reduce devminsize
## (= absolute minimum we need as devdata)
## NEW: define an alternative small size for DEV and TEST
## OLD DEVMINSIZE:
# DEVMINSIZE  = 1000

DEVSMALLSIZE  = 1000
TESTSMALLSIZE = 1000
DEVMINSIZE    = 250

## size of heldout data for each sub-corpus
## (only if there is at least twice as many examples in the corpus)
HELDOUTSIZE = ${DEVSIZE}

##----------------------------------------------------------------------------
## train/dev/test data
##----------------------------------------------------------------------------

## dev/test data: default = Tatoeba otherwise, GlobalVoices, JW300, GNOME or bibl-uedin
## - check that data exist
## - check that there are at least 2 x DEVMINSIZE examples
## TODO: this does not work well for multilingual models!
## TODO: find a better solution than looking into *.info files (use OPUS API?)

ifneq ($(wildcard ${OPUSHOME}/Tatoeba/latest/moses/${LANGPAIR}.txt.zip),)
ifeq ($(shell if (( `head -1 ${OPUSHOME}/Tatoeba/latest/info/${LANGPAIR}.txt.info` \
		    > $$((${DEVMINSIZE} + ${DEVMINSIZE})) )); then echo "ok"; fi),ok)
  DEVSET = Tatoeba
endif
endif

## backoff to GlobalVoices
ifndef DEVSET
ifneq ($(wildcard ${OPUSHOME}/GlobalVoices/latest/moses/${LANGPAIR}.txt.zip),)
ifeq ($(shell if (( `head -1 ${OPUSHOME}/GlobalVoices/latest/info/${LANGPAIR}.txt.info` \
		    > $$((${DEVMINSIZE} + ${DEVMINSIZE})) )); then echo "ok"; fi),ok)
  DEVSET = GlobalVoices
endif
endif
endif

## backoff to infopankki
ifndef DEVSET
ifneq ($(wildcard ${OPUSHOME}/infopankki/latest/moses/${LANGPAIR}.txt.zip),)
ifeq ($(shell if (( `head -1 ${OPUSHOME}/infopankki/latest/info/${LANGPAIR}.txt.info` \
		    > $$((${DEVMINSIZE} + ${DEVMINSIZE})) )); then echo "ok"; fi),ok)
  DEVSET = infopankki
endif
endif
endif

## backoff to JW300
ifndef DEVSET
ifneq ($(wildcard ${OPUSHOME}/JW300/latest/xml/${LANGPAIR}.xml.gz),)
ifeq ($(shell if (( `sed -n 2p ${OPUSHOME}/JW300/latest/info/${LANGPAIR}.info` \
		    > $$((${DEVMINSIZE} + ${DEVMINSIZE})) )); then echo "ok"; fi),ok)
  DEVSET = JW300
endif
endif
endif

## otherwise: bible-uedin
ifndef DEVSET
  DEVSET = bible-uedin
endif


## increase dev/test sets for Tatoeba (very short sentences!)
ifeq (${DEVSET},Tatoeba)
  DEVSIZE = 5000
  TESTSIZE = 5000
endif


## in case we want to use some additional data sets
# EXTRA_TRAINSET =

## TESTSET= DEVSET, TRAINSET = OPUS - WMT-News,DEVSET.TESTSET
TESTSET  ?= ${DEVSET}
TRAINSET ?= $(filter-out WMT-News MPC1 ${DEVSET} ${TESTSET},${OPUSCORPORA} ${EXTRA_TRAINSET})
TUNESET  ?= OpenSubtitles
MONOSET  ?= $(filter-out WMT-News MPC1 ${DEVSET} ${TESTSET},${OPUSMONOCORPORA} ${EXTRA_TRAINSET})

## 1 = use remaining data from dev/test data for training
USE_REST_DEVDATA ?= 1


##----------------------------------------------------------------------------
## pre-processing and vocabulary
##----------------------------------------------------------------------------

BPESIZE    ?= 32000
SRCBPESIZE ?= ${BPESIZE}
TRGBPESIZE ?= ${BPESIZE}

VOCABSIZE  ?= $$((${SRCBPESIZE} + ${TRGBPESIZE} + 1000))

## for document-level models
CONTEXT_SIZE = 100

## pre-processing type
# PRE     = norm
PRE       = simple
PRE_SRC   = spm${SRCBPESIZE:000=}k
PRE_TRG   = spm${TRGBPESIZE:000=}k


##-------------------------------------
## default name of the data set (and the model)
##-------------------------------------

ifndef DATASET
  DATASET = opus
endif

ifndef BPEMODELNAME
  BPEMODELNAME = opus
endif

##-------------------------------------
## OLD OLD OLD
## name of the data set (and the model)
##  - single corpus = use that name
##  - multiple corpora = opus
## add also vocab size to the name
##-------------------------------------

ifndef OLDDATASET
ifeq (${words ${TRAINSET}},1)
  OLDDATASET = ${TRAINSET}
else
  OLDDATASET = opus
endif
endif



## DATADIR = directory where the train/dev/test data are
## WORKDIR = directory used for training

DATADIR  = ${WORKHOME}/data
WORKDIR  = ${WORKHOME}/${LANGPAIRSTR}
MODELDIR = ${WORKHOME}/models/${LANGPAIRSTR}
SPMDIR   = ${WORKHOME}/SentencePieceModels

## data sets
TRAIN_BASE = ${WORKDIR}/train/${DATASET}
TRAIN_SRC  = ${TRAIN_BASE}.src
TRAIN_TRG  = ${TRAIN_BASE}.trg
TRAIN_ALG  = ${TRAIN_BASE}${TRAINSIZE}.${PRE_SRC}-${PRE_TRG}.src-trg.alg.gz

## training data in local space
LOCAL_TRAIN_SRC = ${TMPDIR}/${LANGPAIRSTR}/train/${DATASET}.src
LOCAL_TRAIN_TRG = ${TMPDIR}/${LANGPAIRSTR}/train/${DATASET}.trg
LOCAL_MONO_DATA = ${TMPDIR}/${LANGSTR}/train/${DATASET}.mono

TUNE_SRC  = ${WORKDIR}/tune/${TUNESET}.src
TUNE_TRG  = ${WORKDIR}/tune/${TUNESET}.trg

## dev and test data come from one specific data set
## if we have a bilingual model

ifeq (${words ${SRCLANGS}},1)
ifeq (${words ${TRGLANGS}},1)

  DEV_SRC   = ${WORKDIR}/val/${DEVSET}.src
  DEV_TRG   = ${WORKDIR}/val/${DEVSET}.trg

  TEST_SRC  = ${WORKDIR}/test/${TESTSET}.src
  TEST_TRG  = ${WORKDIR}/test/${TESTSET}.trg

endif
endif

## otherwise we give them a generic name

DEV_SRC   ?= ${WORKDIR}/val/${DATASET}-dev.src
DEV_TRG   ?= ${WORKDIR}/val/${DATASET}-dev.trg

TEST_SRC  ?= ${WORKDIR}/test/${DATASET}-test.src
TEST_TRG  ?= ${WORKDIR}/test/${DATASET}-test.trg



## heldout data directory (keep one set per data set)
HELDOUT_DIR  = ${WORKDIR}/heldout

MODEL_SUBDIR =
MODEL        = ${MODEL_SUBDIR}${DATASET}${TRAINSIZE}.${PRE_SRC}-${PRE_TRG}
MODELTYPE    = transformer-align
NR           = 1

MODEL_BASENAME  = ${MODEL}.${MODELTYPE}.model${NR}
MODEL_VALIDLOG  = ${MODEL}.${MODELTYPE}.valid${NR}.log
MODEL_TRAINLOG  = ${MODEL}.${MODELTYPE}.train${NR}.log
MODEL_START     = ${WORKDIR}/${MODEL_BASENAME}.npz
MODEL_FINAL     = ${WORKDIR}/${MODEL_BASENAME}.npz.best-perplexity.npz
MODEL_VOCABTYPE = yml
MODEL_VOCAB     = ${WORKDIR}/${MODEL}.vocab.${MODEL_VOCABTYPE}
MODEL_DECODER   = ${MODEL_FINAL}.decoder.yml


## test set translation and scores

TEST_TRANSLATION = ${WORKDIR}/${TESTSET}.${MODEL}${NR}.${MODELTYPE}.${SRC}.${TRG}
TEST_EVALUATION  = ${TEST_TRANSLATION}.eval
TEST_COMPARISON  = ${TEST_TRANSLATION}.compare



## parameters for running Marian NMT

MARIAN_GPUS             = 0
MARIAN_EXTRA            = 
MARIAN_VALID_FREQ       = 10000
MARIAN_SAVE_FREQ        = ${MARIAN_VALID_FREQ}
MARIAN_DISP_FREQ        = ${MARIAN_VALID_FREQ}
MARIAN_EARLY_STOPPING   = 10
MARIAN_VALID_MINI_BATCH = 16
MARIAN_MAXI_BATCH       = 500
MARIAN_DROPOUT          = 0.1
MARIAN_MAX_LENGTH	= 500

MARIAN_DECODER_GPU    = -b 12 -n1 -d ${MARIAN_GPUS} --mini-batch 8 --maxi-batch 32 --maxi-batch-sort src \
			--max-length ${MARIAN_MAX_LENGTH} --max-length-crop
MARIAN_DECODER_CPU    = -b 12 -n1 --cpu-threads ${HPC_CORES} --mini-batch 8 --maxi-batch 32 --maxi-batch-sort src \
			--max-length ${MARIAN_MAX_LENGTH} --max-length-crop
MARIAN_DECODER_FLAGS = ${MARIAN_DECODER_GPU}

## TODO: currently marianNMT crashes with workspace > 26000
ifeq (${GPU},p100)
  MARIAN_WORKSPACE = 13000
else ifeq (${GPU},v100)
  # MARIAN_WORKSPACE = 30000
  # MARIAN_WORKSPACE = 26000
  MARIAN_WORKSPACE = 24000
  # MARIAN_WORKSPACE = 18000
  # MARIAN_WORKSPACE = 16000
else
  MARIAN_WORKSPACE = 10000
endif


ifeq (${shell nvidia-smi | grep failed | wc -l},1)
  MARIAN = ${MARIANCPU}
  MARIAN_DECODER_FLAGS = ${MARIAN_DECODER_CPU}
  MARIAN_EXTRA = --cpu-threads ${HPC_CORES}
endif




ifneq ("$(wildcard ${TRAIN_WEIGHTS})","")
	MARIAN_TRAIN_WEIGHTS = --data-weighting ${TRAIN_WEIGHTS}
endif


### training a model with Marian NMT
##
## NR allows to train several models for proper ensembling
## (with shared vocab)
##
## DANGER: if several models are started at the same time
## then there is some racing issue with creating the vocab!

ifdef NR
  SEED=${NR}${NR}${NR}${NR}
else
  SEED=1234
endif



## make some data size-specific configuration parameters
## TODO: is it OK to delete LOCAL_TRAIN data?

local-config: ${WORKDIR}/config.mk

${WORKDIR}/config.mk:
	mkdir -p ${dir $@}
	if [ -e ${TRAIN_SRC}.clean.${PRE_SRC}${TRAINSIZE}.gz ]; then \
	  s=`zcat ${TRAIN_SRC}.clean.${PRE_SRC}${TRAINSIZE}.gz | head -10000001 | wc -l`; \
	else \
	  ${MAKE} ${LOCAL_TRAIN_SRC}; \
	  s=`head -10000001 ${LOCAL_TRAIN_SRC} | wc -l`; \
	  rm -f ${LOCAL_TRAIN_SRC} ${LOCAL_TRAIN_TRG}; \
	fi; \
	if [ $$s -gt 10000000 ]; then \
	  echo "# ${LANGPAIRSTR} training data bigger than 10 million" > $@; \
	  echo "GPUJOB_HPC_MEM = 8g"       >> $@; \
	  echo "GPUJOB_SUBMIT  = -multipu" >> $@; \
	elif [ $$s -gt 1000000 ]; then \
	  echo "# ${LANGPAIRSTR} training data bigger than 1 million" > $@; \
	  echo "GPUJOB_HPC_MEM = 8g"       >> $@; \
	  echo "GPUJOB_SUBMIT  = "         >> $@; \
	  echo "MARIAN_VALID_FREQ = 2500"  >> $@; \
	elif [ $$s -gt 500000 ]; then \
	  echo "# ${LANGPAIRSTR} training data bigger than 500k" > $@; \
	  echo "GPUJOB_HPC_MEM = 4g"       >> $@; \
	  echo "GPUJOB_SUBMIT  = "         >> $@; \
	  echo "MARIAN_VALID_FREQ = 2500"  >> $@; \
	  echo "MARIAN_WORKSPACE  = 10000" >> $@; \
	  echo "BPESIZE = 12000"           >> $@; \
	elif [ $$s -gt 100000 ]; then \
	  echo "# ${LANGPAIRSTR} training data bigger than 100k" > $@; \
	  echo "GPUJOB_HPC_MEM = 4g"       >> $@; \
	  echo "GPUJOB_SUBMIT  = "         >> $@; \
	  echo "MARIAN_VALID_FREQ = 1000"  >> $@; \
	  echo "MARIAN_WORKSPACE  = 5000"  >> $@; \
	  echo "MARIAN_VALID_MINI_BATCH = 8" >> $@; \
	  echo "HELDOUTSIZE = 0"           >> $@; \
	  echo "BPESIZE     = 4000"        >> $@; \
	  echo "DEVSIZE     = 1000"        >> $@; \
	  echo "TESTSIZE    = 1000"        >> $@; \
	  echo "DEVMINSIZE  = 250"         >> $@; \
	elif [ $$s -gt 10000 ]; then \
	  echo "# ${LANGPAIRSTR} training data less than 100k" > $@; \
	  echo "GPUJOB_HPC_MEM = 4g"       >> $@; \
	  echo "GPUJOB_SUBMIT  = "         >> $@; \
	  echo "MARIAN_VALID_FREQ = 1000"  >> $@; \
	  echo "MARIAN_WORKSPACE  = 3500"  >> $@; \
	  echo "MARIAN_DROPOUT    = 0.5"   >> $@; \
	  echo "MARIAN_VALID_MINI_BATCH = 4" >> $@; \
	  echo "HELDOUTSIZE = 0"           >> $@; \
	  echo "BPESIZE     = 1000"        >> $@; \
	  echo "DEVSIZE     = 500"         >> $@; \
	  echo "TESTSIZE    = 1000"        >> $@; \
	  echo "DEVMINSIZE  = 100"         >> $@; \
	else \
	    echo "${LANGPAIRSTR} too small"; \
	fi

