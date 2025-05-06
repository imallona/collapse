#!/bin/bash

# sherborne-proof imallona's DEV hotfixed branch ob install
#
# execute interactively, not as a script, because some human-driven debugging is happening
# better run on a tmux, e.g. tmux new -s dev_ob


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

# we clone a dev_hotfix branch named `reduce_install_scope`
# more details at https://github.com/omnibenchmark/omnibenchmark/pull/110/
git clone git@github.com:omnibenchmark/omnibenchmark.git -b reduce_install_scope

cd omnibenchmark

micromamba activate
micromamba create -n omnibenchmark
micromamba activate omnibenchmark

## we install the whole environment
micromamba install --yes -f test-environment.yml

## conda found now has to succeed (printing a json), we have installed it: ping `imallona` if it doesn't succeed
conda info --json
ob --version

## let's run the clustering

cd ~/collapse

git clone git@github.com:omnibenchmark/clustering_example.git
cd clustering_example

ob run benchmark -b Clustering_conda.yml --local --cores 20

