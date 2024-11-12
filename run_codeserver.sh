#!/bin/bash

# Definicje portów
export mumax_port=35999
export code_port=8090
export remote_host="orion"

# Funkcja do uruchomienia autossh z odwrotnym tunelowaniem
setup_reverse_tunnel() {
    local local_port=$1
    local remote_port=$1
    autossh -M 0 -f -N -R ${remote_port}:localhost:${local_port} ${remote_host}
    echo "Reverse SSH tunnel established for port ${local_port} on ${remote_host}:${remote_port}"
}

# 1. Uruchomienie code-server na lokalnym porcie $code_port
echo "Starting code-server on port ${code_port}..."
code-server --port ${code_port} --host 0.0.0.0 --auth none &
code_server_pid=$!
echo "code-server PID: ${code_server_pid}"

# 2. Ustawienie odwrotnego tunelowania dla code-server
setup_reverse_tunnel ${code_port}

# 3. Uruchomienie amumax na lokalnym porcie $mumax_port
echo "Starting amumax on port ${mumax_port}..."
amumax -http :${mumax_port} &
mumax_pid=$!
echo "amumax PID: ${mumax_pid}"

# 4. Ustawienie odwrotnego tunelowania dla amumax
setup_reverse_tunnel ${mumax_port}

# Funkcja czyszcząca po zakończeniu
cleanup() {
    echo "Stopping code-server and amumax..."
    kill ${code_server_pid}
    kill ${mumax_pid}
    echo "Tunnels and services stopped."
}

# Uruchom cleanup na zakończenie skryptu lub przerwanie
trap cleanup EXIT

# Informacja o dostępnych usługach
echo "code-server is accessible on ${remote_host}:$code_port"
echo "amumax is accessible on ${remote_host}:$mumax_port"

# Keep the script running to maintain the background processes
wait
