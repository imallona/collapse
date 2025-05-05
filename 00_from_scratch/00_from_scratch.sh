#!/bin/bash
#
# sherborne-proof main ob install
# execute interactively, not as a script, because some human-driven debugging is happening
# caution it might fail for `ob run` commands with lots of threads due to a git cloning race condition (ask Daniel)
#
# better run on a tmux, e.g. tmux new -s collapse


## we'll work on ~/collapse and start installing micromamba
mkdir -p ~/collapse/micromamba
cd $_

## we nuke the path
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

## we remove any trace of old micromamba; delete if you prefer
mv -f ~/micromamba{,.DELETEME}  2>/dev/null

## envs will go here, create the folder manually
mkdir -p ~/micromamba

# install a linux Intel (x86_64) micromamba
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

# we control which micromamba are we talking about- the new one
export PATH=~/collapse/micromamba/bin:$PATH

# and modify the shell
eval "$(micromamba shell hook --shell bash)"

# this should work
micromamba --version

## has to fail: we haven't installed any conda; ping `imallona` if it doesn't fail
conda info --json

# do not use ob dev; clone ob main instead
git clone git@github.com:omnibenchmark/omnibenchmark.git -b main

cd omnibenchmark

micromamba activate
micromamba create -n omnibenchmark
micromamba activate omnibenchmark

# we create something sane for an env - pinning python 3.12 etc
cat << EOF > sane_env.yml
channels:
  - conda-forge
  - bioconda
  - nodefaults
dependencies:
  - conda-forge::python == 3.12
  - conda-forge::mamba == 1.5.8
  - conda-forge::lmod == 8.7.25
  - conda-forge::pip >= 24.1.2
  - conda-forge::datrie >= 0.8.2 # dep for snakemake, workaround for https://github.com/astral-sh/uv/issues/7525
  - pip:
     - "."
EOF

## we install the sane env
micromamba install -f sane_env.yml

## conda found now has to succeed, we have installed it: ping `imallona` if it doesn't succeed
conda info --json
ob --version

## let's run the clustering

cd ~/collapse

git clone git@github.com:omnibenchmark/clustering_example.git
cd clustering_example

## clustering but without metrics collection, and rather short
cat <<EOF > nometrics_conda.yml
id: clustering_example_conda
description: Clustering benchmark on Gagolewski's, true number of clusters plus minus 2.
version: 1.4
benchmarker: "Izaskun Mallona, Daniel Incicau"
storage: http://omnibenchmark.org:9000
benchmark_yaml_spec: 0.04
storage_api: S3
storage_bucket_name: clusteringexampleconda
software_backend: conda
software_environments:
  clustbench:
    description: "clustbench on py3.12.6"
    conda: envs/clustbench.yml
    envmodule: clustbench
    apptainer: envs/clustbench.sif
  sklearn:
    description: "Daniel's on py3.12.6"
    conda: envs/sklearn.yml
    apptainer: envs/sklearn.sif
    envmodule: clustbench # not true, but
  R:
    description: "Daniel's R with readr, dplyr, mclust, caret"
    conda: envs/r.yml
    apptainer: envs/r.sif
    envmodule: fcps # not true, but
  rmarkdown:
    description: "R with some plotting dependencies"
    conda: envs/rmarkdown.yml
    apptainer: envs/r.sif # not true, but
    envmodule: fcps # not true, but
  fcps:
    description: "CRAN's FCPS"
    conda: envs/fcps.yml
    apptainer: envs/fcps.sif
    envmodule: fcps
# metric_collectors:
#   - id: plotting
#     name: "Single-backend metric collector."
#     software_environment: "rmarkdown"
#     repository:
#       url: https://github.com/imallona/clustering_report
#       commit: f1a5876
#     inputs:
#       - metrics.scores
#     outputs:
#       - id: plotting.html
#         path: "{input}/{name}/plotting_report.html"
stages:
  ## clustbench data ##########################################################

  - id: data
    modules:
      - id: clustbench
        name: "clustbench datasets, from https://www.sciencedirect.com/science/article/pii/S0020025521010082#t0005 Table1"
        software_environment: "clustbench"
        repository:
          url: https://github.com/imallona/clustbench_data
          commit: 366c5a2
        parameters:  # comments depict the possible cardinalities and the number of curated labelsets
          - values: ["--dataset_generator", "fcps", "--dataset_name", "atom"] #	2	1
          - values: ["--dataset_generator", "fcps", "--dataset_name", "chainlink"] #	2	1
          - values: ["--dataset_generator", "fcps", "--dataset_name", "engytime"] #	2	2
          - values: ["--dataset_generator", "sipu", "--dataset_name", "unbalance"] #	8	1
          - values: ["--dataset_generator", "uci", "--dataset_name", "ecoli"] #	8	1
    outputs:
      - id: data.matrix
        path: "{input}/{stage}/{module}/{params}/{dataset}.data.gz"
      - id: data.true_labels
        path: "{input}/{stage}/{module}/{params}/{dataset}.labels0.gz"

  ## clustbench methods (fastcluster) ###################################################################
  
  - id: clustering
    modules:
      - id: fastcluster
        name: "fastcluster algorithm"
        software_environment: "clustbench"
        repository:
          url: https://github.com/imallona/clustbench_fastcluster
          # url: /home/imallona/src/clustbench_fastcluster/
          commit: "45e43d3"
        parameters:
          - values: ["--linkage", "complete"]
          - values: ["--linkage", "ward"]
          - values: ["--linkage", "average"]
          - values: ["--linkage", "weighted"]
          - values: ["--linkage", "median"]
          - values: ["--linkage", "centroid"]
      - id: sklearn
        name: "sklearn"
        software_environment: "clustbench"
        repository:
          url: https://github.com/imallona/clustbench_sklearn
          #url: /home/imallona/src/clustbench_sklearn
          commit: 5877378
        parameters:
          - values: ["--method", "birch"]
          - values: ["--method", "kmeans"]
          # - values: ["--method", "spectral"] ## too slow
          - values: ["--method", "gm"]
      - id: agglomerative
        name: "agglomerative"
        software_environment: "clustbench"
        repository:
          url: https://github.com/imallona/clustbench_agglomerative
          commit: 5454368
        parameters:
          - values: ["--linkage", "average"]
          - values: ["--linkage", "complete"]
          - values: ["--linkage", "ward"]
      - id: genieclust
        name: "genieclust"
        software_environment: "clustbench"
        repository:
          url: https://github.com/imallona/clustbench_genieclust
          commit: 6090043
        parameters:
          - values: ["--method", "genie", "--gini_threshold", 0.5]
          - values: ["--method", "gic"]
          - values: ["--method", "ica"]
      - id: fcps
        name: "fcps"
        software_environment: "fcps"
        repository:
          url: https://github.com/imallona/clustbench_fcps
          commit: 272fa5f
        parameters:
          # - values: ["--method", "FCPS_AdaptiveDensityPeak"] # not in conda
          - values: ["--method", "FCPS_Minimax"]
          - values: ["--method", "FCPS_MinEnergy"]
          - values: ["--method", "FCPS_HDBSCAN_2"]
          - values: ["--method", "FCPS_HDBSCAN_4"]
          # - values: ["--method", "FCPS_HDBSCAN_8"]
          # - values: ["--method", "FCPS_Diana"]
          # - values: ["--method", "FCPS_Fanny"]
          - values: ["--method", "FCPS_Hardcl"]
          - values: ["--method", "FCPS_Softcl"]
          # - values: ["--method", "FCPS_Clara"]
          - values: ["--method", "FCPS_PAM"]
    inputs:
      - entries:
          - data.matrix
          - data.true_labels
    outputs:
      - id: clustering.predicted_ks_range
        path: "{input}/{stage}/{module}/{params}/{dataset}_ks_range.labels.gz"

  - id: metrics
    modules:
      - id: partition_metrics
        name: "clustbench partition metrics"
        software_environment: "clustbench"
        repository:
          url: https://github.com/imallona/clustbench_metrics
          commit: 9132d45
        parameters:
          - values: ["--metric", "normalized_clustering_accuracy"]
          - values: ["--metric", "adjusted_fm_score"]
          - values: ["--metric", "adjusted_mi_score"]
          - values: ["--metric", "adjusted_rand_score"]
          - values: ["--metric", "fm_score"]
          - values: ["--metric", "mi_score"]
          - values: ["--metric", "normalized_clustering_accuracy"]
          - values: ["--metric", "normalized_mi_score"]
          - values: ["--metric", "normalized_pivoted_accuracy"]
          - values: ["--metric", "pair_sets_index"]
          - values: ["--metric", "rand_score"]
    inputs:
      - entries:
          - clustering.predicted_ks_range
          - data.true_labels
    outputs:
      - id: metrics.scores
        path: "{input}/{stage}/{module}/{params}/{dataset}.scores.gz"

EOF

## caution the race condition with multiple clonings wasn't fixed here so use low amount of cores
## that is, https://github.com/omnibenchmark/omnibenchmark/pull/53
ob run benchmark -b nometrics_conda.yml --local --threads 2

