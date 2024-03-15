#!/bin/bash

function install_packages {
    # Install oath-toolkit and openfortivpn if not already installed
    for pkg in oathtool openfortivpn; do
        if ! command -v $pkg &> /dev/null; then
            echo "Installing $pkg..."
            sudo apt-get install -y $pkg
        fi
    done
}

dir_address=""

function create_config {
    # Get the directory address from the user
    read -p "Enter the directory address you want to create openfortivpn: " dir_address

    # Create directory if it doesn't exist
    mkdir -p "$dir_address"
    echo "Directory created at: $dir_address"

    # Create/open the config file for openfortivpn
    config_file="$dir_address/config"
    if [ ! -f "$config_file" ]; then
        echo "Creating new config file: $config_file"
        read -p "Enter your username: " username
        read -s -p "Enter your password: " password
        read -p "Enter your host: " host
        read -p "Enter your port: " port
        echo -e "\nhost = $host" > "$config_file"
        echo "port = $port" >> "$config_file"
        echo "username = $username" >> "$config_file"
        echo "password = $password" >> "$config_file"
        echo "set-dns = 0" >> "$config_file"
        echo "pppd-use-peerdns = 0" >> "$config_file"
        echo "Config file created successfully!"
    else
        echo "Config file already exists at: $config_file"
    fi
}

function create_script {
    # Check if the config file exists
    config_file=~/.openfortivpn/config
    if [ ! -f "$config_file" ]; then
        echo "Warning: Config file does not exist at: $config_file"
        read -p "Do you want to create the config file in a new directory? (y/n): " create_config
        if [[ $create_config == 'y' || $create_config == 'Y' ]]; then
            create_config
        else
            echo "Continuing without creating config file..."
        fi
    fi

    # Ask the user where they want to create the script
    read -p "Enter the directory address where you want to create the script: " dir_address

    # Create directory if it doesn't exist
    mkdir -p "$script_dir"

    # Create the connect.sh script
    connect_script="$script_dir/connect.sh"
    if [ ! -f "$connect_script" ]; then
        echo "Creating new connect.sh script: $connect_script"
        read -p "Enter your secret: " SECRET
        cat <<EOF > "$connect_script"
#!/bin/bash

SECRET=$SECRET
OTP=\$(oathtool --totp --base32 \$SECRET)
sudo openfortivpn -c /etc/openfortivpn/config --otp \$OTP
EOF
        chmod +x "$connect_script"
        echo "connect.sh script created successfully at: $connect_script"
    else
        echo "connect.sh script already exists at: $connect_script"
    fi
}

function remove_script {
    # Remove the connect.sh script
    connect_script="$dir_address/connect.sh"
    if [ -f "$connect_script" ]; then
        rm "$connect_script"
        echo "connect.sh script removed successfully!"
    else
        echo "Error: connect.sh script does not exist at: $connect_script"
        echo "Please create the connect.sh script first."
        return 1
    fi
}

function remove_dir {
    # Remove the directory
    if [ -d "$dir_address" ]; then
        rm -r "$dir_address"
        echo "$dir_address directory removed successfully!"
    else
        echo "Error: $dir_address directory does not exist."
        echo "Please create the $dir_address directory first."
        return 1
    fi
}

function remove_script_and_dir {
    PS3='Please enter your choice: '
    options=("Remove Script" "Remove Directory" "Remove Both" "Back")
    select opt in "${options[@]}"
    do
        case $opt in
            "Remove Script")
                remove_script
                ;;
            "Remove Directory")
                remove_dir
                ;;
            "Remove Both")
                remove_script
                remove_dir
                ;;
            "Back")
                break
                ;;
            *) echo "Invalid option $REPLY";;
        esac
    done
}

function edit_config {
    # Open the config file for openfortivpn with vim
    config_file=~/.openfortivpn/config
    if [ -f "$config_file" ]; then
        vim "$config_file"
    else
        echo "Error: Config file does not exist at: $config_file"
        echo "Please create the config file first."
        return 1
    fi
}
function edit_script {
    # Open the connect.sh script with vim
    connect_script=~/.openfortivpn/connect.sh
    if [ -f "$connect_script" ]; then
        vim "$connect_script"
    else
        echo "Error: connect.sh script does not exist at: $connect_script"
        echo "Please create the connect.sh script first."
        return 1
    fi
}

function create_config_menu {
    PS3='Please enter your choice: '
    options=("Create directory and config file for openfortivpn" "Create Automating-Script for Openfortivpn and OATH-Tool" "Back")
    select opt in "${options[@]}"
    do
        case $opt in
            "Create directory and config file for openfortivpn")
                create_config
                ;;
            "Create Automating-Script for Openfortivpn and OATH-Tool")
                create_script
                ;;
            "Back")
                break
                ;;
            *) echo "Invalid option $REPLY. Please enter a valid option."; continue;;
        esac
    done
}

function edit_configs_menu {
    PS3='Please enter your choice: '
    options=("Edit Config file openfortivpn" "Edit connect.sh script" "Back")
    select opt in "${options[@]}"
    do
        case $opt in
            "Edit Config file openfortivpn")
                edit_config
                ;;
            "Edit connect.sh script")
                edit_script
                ;;
            "Back")
                break
                ;;
            *) echo "Invalid option $REPLY. Please enter a valid option."; continue;;
        esac
    done
}

PS3='Please enter your choice: '
options=("Install Packages" "Create config file openfortivpn or automating-script" "Remove Automating-Script and Directorys" "Edit either the openfortivpn config file or the connect.sh script" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install Packages")
            install_packages
            ;;
        "Create config file openfortivpn or automating-script")
            create_config_menu
            ;;
        "Remove Automating-Script and Directorys")
            remove_script_and_dir
            ;;
        "Edit either the openfortivpn config file or the connect.sh script")
            edit_configs_menu
            ;;
        "Quit")
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done