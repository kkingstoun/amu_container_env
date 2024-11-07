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

# modprobe nvidia_uvm
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
