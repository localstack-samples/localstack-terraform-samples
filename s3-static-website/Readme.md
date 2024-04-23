# S3 Static Website

This project contains a script to deploy a static website to an S3 bucket on LocalStack and a Makefile to automate the process.

## Prerequisites

- LocalStack
- AWS CLI
- Python
- pip
- make

## Setup

1. Clone this repository and navigate to the `s3-static-website` folder.
2. Run the `deploy.ps1` script with the appropriate switches to perform the desired operations, or use the `Makefile`.

## Usage

### PowerShell Script

The `deploy.ps1` script supports the following switches:

- `-InstallDependencies`: Installs the necessary dependencies for the script to run.
- `-Deploy`: Creates a bucket, sets a bucket policy, syncs a local directory to the bucket, and sets up a website on the bucket.
- `-Start`: Starts LocalStack in detached mode.
- `-Stop`: Stops LocalStack.
- `-Ready`: Waits for LocalStack to be ready for use.
- `-Logs`: Writes LocalStack logs to a text file.

For example, to install dependencies and start LocalStack, you would run:

```powershell
.\deploy.ps1 -InstallDependencies -Start -Ready -Deploy
```

### Makefile

You can also use the Makefile to automate the process. The Makefile supports the following commands:

- `make install`: Installs the necessary dependencies.
- `make run`: Creates a bucket, sets a bucket policy, syncs a local directory to the bucket, and sets up a website on the bucket.
- `make start`: Starts LocalStack in detached mode.
- `make stop:` Stops LocalStack.
- `make ready`: Waits for LocalStack to be ready for use.
- `make logs`: Writes LocalStack logs to a text file.
- `make test-ci`: Runs all the commands in sequence to test the CI process.

For example, to install dependencies and start LocalStack, you would run:

```bash
make install run
```
