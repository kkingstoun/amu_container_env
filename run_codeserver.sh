#!/bin/bash

# Configuration
export remote_host="orion"
declare -A services=(
    ["code-server"]="8090"
    ["amumax"]="35999"
)

# Port management
used_ports=()
pid_file="/tmp/port_forward_$USER.pid"

# Improved tunnel setup with retry and monitoring
setup_reverse_tunnel() {
    local service=$1
    local local_port=$2
    local remote_port=$2
    local retry_count=0
    local max_retries=3

    # Check if port is already in use
    while nc -z localhost $local_port 2>/dev/null; do
        local_port=$((local_port + 1))
        if [[ $local_port -gt $((remote_port + 10)) ]]; then
            echo "ERROR: Could not find available port for $service"
            return 1
        fi
    done

    # Setup tunnel with retry logic
    while [[ $retry_count -lt $max_retries ]]; do
        autossh -M 0 -f -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
                -R ${remote_port}:localhost:${local_port} ${remote_host}
        
        if [[ $? -eq 0 ]]; then
            echo "Reverse SSH tunnel established for $service on ${remote_host}:${remote_port} (local: ${local_port})"
            used_ports+=($local_port)
            return 0
        fi
        
        ((retry_count++))
        echo "Retry $retry_count/$max_retries for $service tunnel"
        sleep 5
    done
    
    echo "ERROR: Failed to establish tunnel for $service after $max_retries attempts"
    return 1
}

# Enhanced service startup
start_service() {
    local service=$1
    local port=${services[$service]}
    
    case $service in
        "code-server")
            echo "Starting $service on port ${port}..."
            code-server --port ${port} --host 0.0.0.0 --auth none &
            local pid=$!
            echo "$service:$pid" >> $pid_file
            setup_reverse_tunnel $service $port
            ;;
        "amumax")
            echo "Starting $service on port ${port}..."
            amumax -http :${port} &
            local pid=$!
            echo "$service:$pid" >> $pid_file
            setup_reverse_tunnel $service $port
            ;;
        *)
            echo "Unknown service: $service"
            return 1
            ;;
    esac
}

# Improved cleanup function
cleanup() {
    echo "Stopping services and tunnels..."
    
    # Kill all services
    if [[ -f $pid_file ]]; then
        while IFS=: read -r service pid; do
            if kill -0 $pid 2>/dev/null; then
                echo "Stopping $service (PID: $pid)"
                kill $pid
            fi
        done < $pid_file
        rm $pid_file
    fi

    # Kill all autossh processes for this user
    pkill -u $USER autossh
    
    # Clean up used ports
    for port in "${used_ports[@]}"; do
        fuser -k $port/tcp 2>/dev/null
    done
    
    echo "Cleanup complete."
}

# Set up signal handling
trap cleanup EXIT INT TERM

# Main execution
echo "Starting services with port forwarding..."

# Create clean PID file
> $pid_file

# Start all configured services
for service in "${!services[@]}"; do
    start_service $service
done

# Status report
echo -e "\nService Status:"
echo "----------------------------------------"
if [[ -f $pid_file ]]; then
    while IFS=: read -r service pid; do
        if kill -0 $pid 2>/dev/null; then
            echo "$service is running (PID: $pid)"
            echo "Access at ${remote_host}:${services[$service]}"
        else
            echo "$service failed to start"
        fi
    done < $pid_file
fi
echo "----------------------------------------"

# Keep script running
wait