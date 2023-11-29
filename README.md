![Automated Virtual Host Creation with Bash Script](https://github.com/noparvar/virtual-host-automation/blob/main/automated-apache-virtual-hosts-creation-with-a-bash-script.jpg?raw=true)

# Automated Virtual Host Creation with Bash Script

If you've ever set up local development environments with Apache, you know the drill – creating folders, editing configuration files, generating self-signed certificates, and updating the hosts file. It's a manual process that can be time-consuming and error-prone.

In this repository, you'll find a bash script that automates the creation of Apache virtual hosts, making it a breeze to set up new projects on your local machine. This script simplifies the process by handling folder creation, configuration file generation, SSL certificate creation, and hosts file updates – all with just a few commands.

## Features

- **Easy Setup**: Quickly create Apache virtual hosts with minimal manual effort.
- **SSL Support**: Enable SSL for your virtual hosts with automatic certificate generation.
- **Customizable**: Tailor the script to your specific needs by adjusting variables and configurations.

## Prerequisites

- Apache web server installed.
- OpenSSL for SSL certificate generation.

## Usage

1. Clone this repository:

    ```bash
    git clone https://github.com/noparvar/virtual-host-automation.git
    cd virtual-host-automation
    ```

2. Make the script executable:

    ```bash
    chmod +x create_vhost.sh
    ```

3. Run the script:

    ```bash
    ./create_vhost.sh -s your-site-name
    ```

    Customize further with options like `-p` for PHP version and `--ssl` for enabling SSL.

## Contribution

Feel free to contribute to the improvement of this script. Submit issues for bugs or enhancements, and pull requests are always welcome.
Visit my blog post [Automated Virtual Host Creation with Bash Script](https://www.noparvar.net/blog/automating-apache-virtual-host-creation-with-a-bash-script/) for more information.

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

Happy coding!
