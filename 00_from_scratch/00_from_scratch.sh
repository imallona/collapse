#!/bin/bash
#
# sherborne-proof main ob install
#
# tmux new -s collapse

mkdir -p ~/collapse/micromamba
cd $_

## we nuke the path
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

## we remove any trace of old micromamba; delete if you prefer
mv ~/micromamba{,.DELETEME}

## envs will go here, create manually
mkdir -p ~/micromamba

# linux Intel (x86_64) micromamba
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

# we control which micromamba are we talking about- the new one
export PATH=~/collapse/micromamba/bin:$PATH

# check versions
micromamba --version
conda info --json

# ob main
git clone git@github.com:omnibenchmark/omnibenchmark.git -b main

cd omnibenchmark

micromamba activate
micromamba create -n omnibenchmark
micromamba activate omnibenchmark

# we create something sane for an env

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


micromamba install -f sane_env.yml

ob --version
conda info --json

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
          - values: ["--dataset_generator", "fcps", "--dataset_name", "hepta"] #	7	1
          - values: ["--dataset_generator", "fcps", "--dataset_name", "lsun"] #	3	1
          - values: ["--dataset_generator", "fcps", "--dataset_name", "target"] #	2, 6	2
          - values: ["--dataset_generator", "fcps", "--dataset_name", "tetra"] #	4	1
          - values: ["--dataset_generator", "fcps", "--dataset_name", "twodiamonds"] #	2	1
          - values: ["--dataset_generator", "fcps", "--dataset_name", "wingnut"] #	2	1
          - values: ["--dataset_generator", "graves", "--dataset_name", "dense"] #	2	1
          - values: ["--dataset_generator", "graves", "--dataset_name", "fuzzyx"] #	2, 4, 5	6
          - values: ["--dataset_generator", "graves", "--dataset_name", "line"] #	2	1
          - values: ["--dataset_generator", "graves", "--dataset_name", "parabolic"] #	2, 4	2
          - values: ["--dataset_generator", "graves", "--dataset_name", "ring"] #	2	1
          # - values: ["--dataset_generator", "graves", "--dataset_name", "ring_noisy"] #	2	1
          # - values: ["--dataset_generator", "graves", "--dataset_name", "ring_outliers"] #	2, 5	2
          # - values: ["--dataset_generator", "graves", "--dataset_name", "zigzag"] #	3, 5	2
          # - values: ["--dataset_generator", "graves", "--dataset_name", "zigzag_noisy"] #	3, 5	2
          # - values: ["--dataset_generator", "graves", "--dataset_name", "zigzag_outliers"] #	3, 5	2
          # - values: ["--dataset_generator", "other", "--dataset_name", "chameleon_t4_8k"] #	6	1
          # - values: ["--dataset_generator", "other", "--dataset_name", "chameleon_t5_8k"] #	6	1
          # - values: ["--dataset_generator", "other", "--dataset_name", "hdbscan"] #	6	1
          # - values: ["--dataset_generator", "other", "--dataset_name", "iris"] #	3	1
          # - values: ["--dataset_generator", "other", "--dataset_name", "iris5"] #	3	1
          # - values: ["--dataset_generator", "other", "--dataset_name", "square"] #	2	1
          # - values: ["--dataset_generator", "sipu", "--dataset_name", "aggregation"] #	7	1
          # - values: ["--dataset_generator", "sipu", "--dataset_name", "compound"] #	4, 5, 6	5
          # - values: ["--dataset_generator", "sipu", "--dataset_name", "flame"] #	2	2
          # - values: ["--dataset_generator", "sipu", "--dataset_name", "jain"] #	2	1
          # - values: ["--dataset_generator", "sipu", "--dataset_name", "pathbased"] #	3, 4	2
          # - values: ["--dataset_generator", "sipu", "--dataset_name", "r15"] #	8, 9, 15	3
          # - values: ["--dataset_generator", "sipu", "--dataset_name", "spiral"] #	3	1
          # - values: ["--dataset_generator", "sipu", "--dataset_name", "unbalance"] #	8	1
          # - values: ["--dataset_generator", "uci", "--dataset_name", "ecoli"] #	8	1
          # - values: ["--dataset_generator", "uci", "--dataset_name", "ionosphere"] #	2	1
          # - values: ["--dataset_generator", "uci", "--dataset_name", "sonar"] #	2	1
          # - values: ["--dataset_generator", "uci", "--dataset_name", "statlog"] #	7	1
          # - values: ["--dataset_generator", "uci", "--dataset_name", "wdbc"] #	2	1
          # - values: ["--dataset_generator", "uci", "--dataset_name", "wine"] #	3	1
          # - values: ["--dataset_generator", "uci", "--dataset_name", "yeast"] #	10	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "circles"] #	4	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "cross"] #	4	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "graph"] #	10	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "isolation"] #	3	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "labirynth"] #	6	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "mk1"] #	3	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "mk2"] #	2	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "mk3"] #	3	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "mk4"] #	3	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "olympic"] #	5	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "smile"] #	4, 6	2
          # - values: ["--dataset_generator", "wut", "--dataset_name", "stripes"] #	2	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "trajectories"] #	4	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "trapped_lovers"] #	3	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "twosplashes"] #	2	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "windows"] #	5	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "x1"] #	3	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "x2"] #	3	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "x3"] #	4	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "z1"] #	3	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "z2"] #	5	1
          # - values: ["--dataset_generator", "wut", "--dataset_name", "z3"] #	4	1
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
          - values: ["--method", "FCPS_HDBSCAN_8"]
          # - values: ["--method", "FCPS_Diana"]
          # - values: ["--method", "FCPS_Fanny"]
          - values: ["--method", "FCPS_Hardcl"]
          - values: ["--method", "FCPS_Softcl"]
          - values: ["--method", "FCPS_Clara"]
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

ob run benchmark -b nometrics_conda.yml --local --threads 6

