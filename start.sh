#!/bin/bash

# Zmienna środowiskowa SINIMAGE_DIR określa zapisywalny katalog użytkownika
export SINIMAGE_DIR="/mnt/local/kkingstoun/sinimage/home"

# Tworzenie wymaganych katalogów w SINIMAGE_DIR, jeśli nie istnieją
mkdir -p $SINIMAGE_DIR
mkdir -p $SINIMAGE_DIR/.config
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
  --bind /mnt/storage_2/:/mnt/storage_2/  \
  --bind "$SINIMAGE_DIR:$SINIMAGE_DIR:rw" \
  --home "$SINIMAGE_DIR" \
  out2.sif
