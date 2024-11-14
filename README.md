## AMU_CONAINER_ENV

<div align="center">
  <img src="./logo.png" alt="Project Logo" width="300px">
</div>

**Containerized Development Environment for Amumax, Pyzfn, and Python**

![License](https://img.shields.io/github/license/kkingstoun/amu_container_env?style=flat&logo=opensourceinitiative&logoColor=white&color=0080ff)
![Last Commit](https://img.shields.io/github/last-commit/kkingstoun/amu_container_env?style=flat&logo=git&logoColor=white&color=0080ff)
![Top Language](https://img.shields.io/github/languages/top/kkingstoun/amu_container_env?style=flat&color=0080ff)
![Languages Count](https://img.shields.io/github/languages/count/kkingstoun/amu_container_env?style=flat&color=0080ff)

Built with the following tools and technologies:

![GNU Bash](https://img.shields.io/badge/GNU%20Bash-4EAA25.svg?style=flat&logo=GNU-Bash&logoColor=white)

---

## Overview

AMU_CONAINER_ENV is a highly portable, containerized development environment dedicated to running simulations and analyses using Amumax, Pyzfn, and Python. It is optimized for use in any environment supporting virtualization and is specifically designed for seamless integration with high-performance computing centers.

---

## Features

- **Amumax Integration**: Supports efficient simulations of magnetization dynamics with Amumax.
- **Python & Pyzfn**: Integrated Python environment with Pyzfn for data analysis and numerical experiments.
- **Code-Server**: Remote VS Code access in a browser, allowing a familiar development environment from anywhere.
- **GPU Acceleration**: Optional GPU support for improved simulation performance.
- **Supercomputing Ready**: Configurable for PCSS infrastructure and other HPC centers, allowing optimal binding and resource management.

---
## Project Structure

```sh
└── pcss_container_env/
    ├── code-server
    │   ├── config.yaml
    │   ├── extensions-list.txt
    │   └── settings.json
    ├── image.def
    ├── starship.toml
    ├── .zshrc
    └── start.sh
```

### Description

- **code-server/**: Contains configuration files (`config.yaml`, `extensions-list.txt`, `settings.json`) that are mounted into the container to set up and customize the VS Code environment. This allows for persistent changes to extensions, editor settings, and other customizations, making the development environment adaptable and user-friendly.
- **starship.toml**: Configuration for the terminal prompt (`starship`) used inside the container. It is mounted to ensure a consistent and personalized terminal prompt across sessions.
- **.zshrc**: Shell configuration file for Zsh. This is mounted to provide custom aliases, environment variables, and settings, ensuring the user's shell environment is consistently configured every time the container is started.

### Project Index
<details open>
	<summary><b>AMU_CONAINER_ENVTAINER_ENV/</b></summary>
	<ul>
		<li><b><a href='https://github.com/kkingstoun/amu_container_env/blob/master/starship.toml'>starship.toml</a></b>: Configuration for the terminal prompt setup.</li>
		<li><b><a href='https://github.com/kkingstoun/amu_container_env/blob/master/image.def'>image.def</a></b>: Singularity definition file to build the container image.</li>
		<li><b><a href='https://github.com/kkingstoun/amu_container_env/blob/master/start.sh'>start.sh</a></b>: Startup script to initialize the container environment.</li>
		<li><b>code-server/</b>
			<ul>
				<li><b><a href='https://github.com/kkingstoun/amu_container_env/blob/master/code-server/config.yaml'>config.yaml</a></b>: Configuration file for Code-Server settings.</li>
				<li><b><a href='https://github.com/kkingstoun/amu_container_env/blob/master/code-server/settings.json'>settings.json</a></b>: VS Code settings for extensions and environment setup.</li>
				<li><b><a href='https://github.com/kkingstoun/amu_container_env/blob/master/code-server/extensions-list.txt'>extensions-list.txt</a></b>: List of VS Code extensions to be installed in the container environment.</li>
			</ul>
		</li>
	</ul>
</details>

---
## Getting Started

### Prerequisites

Before getting started with amu_container_env, ensure your runtime environment meets the following requirements:

- **Singularity**: Ensure that Singularity is installed in your environment.
- **GPU Acceleration (Optional)**: NVIDIA drivers installed for GPU usage.

### Installation

Install amu_container_env using one of the following methods:

**Build from source:**

1. Clone the amu_container_env repository:
```sh
git clone https://github.com/kkingstoun/amu_container_env
```

2. Navigate to the project directory:
```sh
cd amu_container_env
```

3. Pull the container image using Singularity:
```sh
singularity pull --arch amd64 library://kkingstoun/amuenv/amuenv:latest
```

**Note**: You might encounter warnings regarding container verification, which can be safely ignored in most cases.

### Usage

1. Run the startup script to set up the container environment:
```sh
./start.sh
```

2. Start the Code-Server environment to work on your projects using a browser-based VS Code:
```sh
code-server
```

You will see output similar to:
```
[2024-11-08T08:06:57.639Z] info  HTTP server listening on http://0.0.0.0:8080/
[2024-11-08T08:06:57.639Z] info    - Authentication is enabled
[2024-11-08T08:06:57.639Z] info      - Using password from /opt/code-server/config/config.yaml
```
Open your browser and navigate to `http://0.0.0.0:8080/` to access the VS Code environment.

### Customizing Start Script

To bind specific directories as needed, edit the `start.sh` script. For example, to bind `/mnt/storage_2/` to make it available inside the container:

```sh
--bind /mnt/storage_2/:/mnt/storage_2/  \
```

Ensure the required bindings remain unchanged:
```sh
singularity run \
  --no-home \
  --bind /mnt/storage_2/:/mnt/storage_2/  \
  --bind "$SINIMAGE_DIR:$SINIMAGE_DIR:rw" \
  --bind ./code-server:$SINIMAGE_DIR/.local/etc/code-server:rw \
  --bind ./code-server/settings.json:$SINIMAGE_DIR/.local/share/code-server/User/settings.json \
  --home "$SINIMAGE_DIR" \
  amuenv_latest.sif
```

### GPU Support

To enable GPU access within the container, execute the following commands:

```sh
modprobe nvidia_uvm         # ENABLE GPU
```

Then, run the container with the necessary GPU bindings:

```sh
# Run the Singularity container with GPU support
singularity run \
  --nv \                    # ENABLE GPU
  ...
```

## Preparing Windows Client


## Overview
The `Install-SecureSSHServer.ps1` script sets up a secure SSH server on a Windows client, creating a user with SSH key-based access, and configuring necessary permissions and environment settings. This guide will walk you through the prerequisites and installation steps required to run the script effectively.

# Secure SSH Server Installation Script (PowerShell)

⚠️ **Warning: Experimental Software**  
This script is provided as experimental software for automated SSH server configuration on Windows. The author assumes no responsibility for any issues that may arise, including potential system instability or security vulnerabilities. Use this script at your own risk and ensure you have proper system backups before proceeding.

---

## Prerequisites
- **Operating System**: Windows 10/11 or Windows Server 2019/2022
- **PowerShell**: Version 5.1 or newer
- **Administrator Privileges**: The script must be run as an administrator.

## Usage

1. Open PowerShell as an administrator.
2. Navigate to the directory containing the script and run the following commands:

### 1. Prepare the Password
The new SSH user requires a secure password, which will be used in the script. Define this password in PowerShell using the `ConvertTo-SecureString` command.

Example:
```powershell
$NewUserPassword = ConvertTo-SecureString "YourStrongPassword@#!" -AsPlainText -Force
```

### 2. Run the Script
Change to the directory containing the Install-SecureSSHServer.ps1 script and execute it with the required parameters.

Example:

```powershell
cd windows-client/ssh_server/src/

.\Install-SecureSSHServer.ps1 `
    -NewUsername "sshuser" `
    -NewUserPassword $NewUserPassword `
    -Force `
    -sshKeyFolderPath "C:\sshuser"
```

### Script Parameters
- **`-NewUsername`**: Specifies the username to be created for SSH access. Example: `"sshuser"`
- **`-NewUserPassword`**: The password for the SSH user, supplied as a `SecureString`.
- **`-Force`**: (Optional) If provided, removes any existing user with the specified username before creating a new user.
- **`-sshKeyFolderPath`**: (Optional) Directory where SSH keys will be stored. Default is `"C:\sshuser"`.

## Process Overview and Steps

### 1. Install and Configure OpenSSH Components
   - The script checks if OpenSSH Client and Server are installed. If they’re missing, they are added to the system.
   - It configures the SSH service to start automatically with the system.

### 2. Create and Configure SSH User
   - **User Creation**: A new local user account is created with the provided username and password.
   - **Home Directory Initialization**: The script ensures that the user’s home directory is properly initialized. 
   - **SSH Group Membership**: The user is added to a specific SSH group (`SSH Users`), which is created if it doesn’t exist.

### 3. Set Permissions for SSH Directory
   - **Permissions Setup**: The script modifies permissions on the SSH configuration directory (`C:\ProgramData\ssh`) to ensure only administrators and the system have full access.
   - **Permission Confirmation**: If `-NoConfirm` is not set, the user is prompted to confirm these changes.

### 4. Configure sshd_config for Secure Access
   - **Backup Configuration**: A backup of the current `sshd_config` file is created.
   - **Configuration Changes**: Updates are applied to enable key-based authentication, disable root login, and restrict SSH access to members of the `SSH Users` group.
   - **Comparison Display**: The script displays a side-by-side comparison of the current and new `sshd_config` settings, prompting for user confirmation if necessary.

### 5. Configure and Confirm SSH Port
   - **Port Configuration**: The SSH port is checked, and the script provides an option to change it if it’s set to the default (22).
   - **Firewall Rule Setup**: A new firewall rule is created to allow inbound connections on the selected port.

### 6. Generate SSH Key Pair
   - **Key Generation**: If an SSH key pair does not already exist in the specified folder, the script generates one.
   - **Permissions**: Permissions on the generated key files are restricted to ensure they’re only accessible to the system and the SSH user.

### 7. Configure User’s .ssh Folder
   - **.ssh Directory Setup**: The script creates the `.ssh` folder in the user's home directory.
   - **Authorized Keys**: The public key is appended to the `authorized_keys` file to allow passwordless login.
   - **Permissions**: Permissions on `authorized_keys` are set to allow only the SSH user and the system to access it.

### 8. Test SSH Connection
   - The script performs a test SSH connection to `localhost` using the newly created user and key to confirm the setup was successful.

---

## File Modifications

- **`C:\ProgramData\ssh\sshd_config`**: The script backs up and modifies this file to enforce secure settings.
- **`C:\Users\[NewUsername]\.ssh\authorized_keys`**: This file is updated with the public key to enable SSH access.
- **Firewall Rules**: A new firewall rule may be added if the SSH port is modified from the default.

---

## Notes
- **Key Storage**: SSH keys are generated and stored in the specified folder (`-sshKeyFolderPath`) with restricted access permissions.
- **Logging**: The script logs its actions and results to a log file (`$LogPath`), with detailed error handling and informational messages.
- **Administrator Access**: Because the script modifies system files and directories, it must be run with elevated privileges.

--- 

## Recommended Practice for PCSS

Due to frequent issues with read/write speeds on the PCSS storage, it is recommended to clone the repository to a local disk on the Proxima nodes:

🚀 **Executing command:**

```sh
srun -n 1 -c 20 --mem=100G -t 24:00:00 --partition=proxima --gres gpu:1 --pty /bin/bash
```

Then, create a local directory to work in:

```sh
mkdir -p /mnt/local/$(whoami)/env/
```

After creating the directory, execute the container installation instructions (git clone and Singularity commands) within this folder.

Ensure that only the necessary storage directories with data are mounted to minimize potential bottlenecks.


---
## Project Roadmap

- [X] **`Task 1`**: <strike>Initial setup of Amumax, Pyzfn, and Python environment.</strike>
- [X] **`Task 2`**: Implement GPU support verification and testing.
- [X] **`Task 3`**: Integrate additional Python libraries for enhanced data processing.
- [ ] **`Task 4`**: Add [Boris Computational Spintronics](https://www.boris-spintronics.uk/) support. 
- [ ] **`Task 4`**: Add [Neuralmag](https://gitlab.com/neuralmag/neuralmag) support. 
---

## Contributing

- **💬 [Join the Discussions](https://github.com/kkingstoun/amu_container_env/discussions)**: Share your insights, provide feedback, or ask questions.
- **🐛 [Report Issues](https://github.com/kkingstoun/amu_container_env/issues)**: Submit bugs found or log feature requests for the `amu_container_env` project.
- **💡 [Submit Pull Requests](https://github.com/kkingstoun/amu_container_env/blob/main/CONTRIBUTING.md)**: Review open PRs, and submit your own PRs.

<details closed>
<summary>Contributing Guidelines</summary>

1. **Fork the Repository**: Start by forking the project repository to your github account.
2. **Clone Locally**: Clone the forked repository to your local machine using a git client.
   ```sh
   git clone https://github.com/kkingstoun/amu_container_env
   ```
3. **Create a New Branch**: Always work on a new branch, giving it a descriptive name.
   ```sh
   git checkout -b new-feature-x
   ```
4. **Make Your Changes**: Develop and test your changes locally.
5. **Commit Your Changes**: Commit with a clear message describing your updates.
   ```sh
   git commit -m 'Implemented new feature x.'
   ```
6. **Push to github**: Push the changes to your forked repository.
   ```sh
   git push origin new-feature-x
   ```
7. **Submit a Pull Request**: Create a PR against the original project repository. Clearly describe the changes and their motivations.
8. **Review**: Once your PR is reviewed and approved, it will be merged into the main branch. Congratulations on your contribution!
</details>

<details closed>
<summary>Contributor Graph</summary>
<br>
<p align="left">
   <a href="https://github.com/kkingstoun/amu_container_env/graphs/contributors">
      <img src="https://contrib.rocks/image?repo=kkingstoun/amu_container_env">
   </a>
</p>
</details>

---

## License

This project is protected under the [MIT License](https://choosealicense.com/licenses/mit/). For more details, refer to the [LICENSE](https://choosealicense.com/licenses/mit/) file.

---

## Acknowledgments

- Special thanks to the PCSS community for their support.
- Built using [Amumax](https://github.com/MathieuMoalic/amumax), [Pyzfn](https://github.com/MathieuMoalic/pyzfn), and [Code-Server](https://github.com/coder/code-server).

---

## Authors

- [Mateusz Zelent](https://github.com/kkingstoun/) & [Mathieu Moalic](https://github.com/MathieuMoalic)
---
