#!/bin/bash

# Zmienna środowiskowa SINIMAGE_DIR określa zapisywalny katalog użytkownika
export USERNAME=${USER:-$(id -un)}
export SINIMAGE_DIR=/mnt/local/$USERNAME/sinimage/home

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

modprobe nvidia_uvm         #ENABLE GPU
# Uruchomienie kontenera Singularity z odpowiednimi bindami
singularity run \
  --nv \
  --no-home \
  --bind /mnt/storage_2/:/mnt/storage_2/  \
  --bind "$SINIMAGE_DIR:$SINIMAGE_DIR:rw" \
  --bind ./code-server:$SINIMAGE_DIR/.local/etc/code-server:rw \
  --bind ./.zshrc:$SINIMAGE_DIR/.zshrc \
  --bind ./code-server/config.yaml:$SINIMAGE_DIR/.config/code-server/config.yaml \
  --bind ./starship.toml:$SINIMAGE_DIR/.config/starship.toml \
  --bind ./code-server/settings.json:$SINIMAGE_DIR/.local/share/code-server/User/settings.json \
  --home "$SINIMAGE_DIR" \
  amuenv_latest.sif