#!/bin/bash

# Zmienna środowiskowa SINIMAGE_DIR określa zapisywalny katalog użytkownika
export SINIMAGE_DIR="/mnt/local/kkingstoun/sinimage"

# Tworzenie wymaganych katalogów w SINIMAGE_DIR, jeśli nie istnieją
mkdir -p $SINIMAGE_DIR
mkdir -p $SINIMAGE_DIR/home
mkdir -p $SINIMAGE_DIR/conda/pkgs
mkdir -p $SINIMAGE_DIR/conda/envs
mkdir -p $SINIMAGE_DIR/.local/cache/conda
mkdir -p $SINIMAGE_DIR/.local/share/jupyter/runtime
mkdir -p $SINIMAGE_DIR/.local/share/ipython
mkdir -p $SINIMAGE_DIR/.local/etc/jupyter
mkdir -p $SINIMAGE_DIR/.local/share/jupyter
mkdir -p $SINIMAGE_DIR/.local/share/matplotlib
mkdir -p $SINIMAGE_DIR/.local/cache
mkdir -p $SINIMAGE_DIR/.local/etc/code-server

# Upewnij się, że katalogi są zapisywalne
chmod -R 777 $SINIMAGE_DIR

# Zmienne środowiskowe dla Conda i innych narzędzi
export CONDA_PKGS_DIRS=$SINIMAGE_DIR/conda/pkgs
export CONDA_ENVS_DIRS=$SINIMAGE_DIR/conda/envs
export CONDA_CACHE_DIR=$SINIMAGE_DIR/.local/cache/conda
export CONDA_PREFIX=$SINIMAGE_DIR/conda/envs/my_env  # Ustawienia dla środowiska
export PYTHONUSERBASE=$SINIMAGE_DIR/.local
export JUPYTER_RUNTIME_DIR=$SINIMAGE_DIR/.local/share/jupyter/runtime
export IPYTHONDIR=$SINIMAGE_DIR/.local/share/ipython
export JUPYTER_CONFIG_DIR=$SINIMAGE_DIR/.local/etc/jupyter
export JUPYTER_DATA_DIR=$SINIMAGE_DIR/.local/share/jupyter
export MPLCONFIGDIR=$SINIMAGE_DIR/.local/share/matplotlib
export XDG_CONFIG_HOME=$SINIMAGE_DIR/.local/etc
export XDG_DATA_HOME=$SINIMAGE_DIR/.local/share
export XDG_CACHE_HOME=$SINIMAGE_DIR/.local/cache
export JUPYTER_IP="0.0.0.0"
export PATH=$PATH:$SINIMAGE_DIR/conda/envs/my_env/bin
export NVM_DIR=$SINIMAGE_DIR/home/.nvm

modprobe nvidia_uvm
# Uruchomienie kontenera Singularity z odpowiednimi bindami
singularity run \
  --no-home \
  --bind /mnt/local:/mnt/local:rw \
  --bind "$SINIMAGE_DIR:/mnt/local/kkingstoun/sinimage:rw" \
  --bind /mnt/storage_2/:/mnt/storage_2/  \
  --home "$SINIMAGE_DIR/home" \
  --bind "$SINIMAGE_DIR/conda/pkgs:/opt/conda/pkgs:rw" \
  --bind "$SINIMAGE_DIR/.local:/root/.local:rw" \
  --bind "$SINIMAGE_DIR/home:/root:rw" \
out2.sif
