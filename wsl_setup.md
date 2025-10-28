# Instructions:

Download and install "Windows Terminal Preview Installer":

`winget install Microsoft.WindowsTerminal` (or use ths link: [https://apps.microsoft.com/detail/9n0dx20hk701](https://apps.microsoft.com/detail/9n0dx20hk701?hl=en-US&gl=US))

Open windows terminal as Administrator (right click, run as administrator)

Open powershell tab and run following (bold commands):

`whoami`

--> this should give you a domain\userId on windows side.

`wsl --install -d Ubuntu`

it may ask you to create your user, on windows you should prefix with letter p or u or something, as the userId cannot start with a number. Use your SSO password for ubuntu password as that will be easiest to remember.

### Create .wslconfig

`notepad .wslconfig`

add content here to it (w/o triple backticks) and save

```text
[wsl2]

networkingMode=mirrored
```

`wsl --shutdown`

### Zscaler fix

Open "Manage User Certificates" (`certmgr`)

Click on "Trusted Root Certification Authorities" --> "Certificates" and find "Zscaler Root CA", right click and select "All Tasks"-->Export-->next-->Base-64 encoded X.509 (.CER)-->next-->Save as ZscalerRootCA.cer in your Downloads folder.

Open Windows Terminal (Preview); click carrot on tab header and select Ubuntu

Following commands are to be run within Ubuntu (bash shell), if you aren't sure of shell type, just run:

`echo $SHELL`

bash should be the default for Ubuntu 24.04 anyway

Turn off Zscaler Internet and run the following (replace <userId> with your ubuntu userId, i.e. p123456):

`cp /mnt/c/Users/<userId>/Downloads/ZscalerRootCA.cer /usr/local/share/ca-certificates/`

`sudo cp /mnt/c/Users/<userId>/Downloads/ZscalerRootCA.cer /usr/local/share/ca-certificates/`

`sudo apt update`

`sudo apt upgrade -y`

`man openssl` (type q to exit help page) ---> if not installed, run: `sudo apt-get install -y openssl`

`sudo openssl x509 -inform PEM -in /usr/local/share/ca-certificates/ZscalerRootCA.cer -out /usr/local/share/ca-certificates/ZscalerRootCA.crt`

`ls /usr/local/share/ca-certificates/` --> it should show the file is there

`sudo apt install apt-transport-https ca-certificates gnupg curl`

`sudo update-ca-certificates`

If you want, you should be able to to turn zscaler internet back on at this point and run other commands, if any command hangs or seems to give you SSL error issue, just turn zscaler internet back off

### Install python \& JDK

`sudo apt-get install -y python3 python3-pip python-is-python3 python3-venv`

`sudo apt-get install -y openjdk-17-jdk`

`java --version` ### (this should show OpenJDK ... build 17.x...)

### Install GCM (Git Credential Manager) Linux side

`curl -L https://aka.ms/gcm/linux-install-source.sh | bash`

> [NOTE]:
>
> This will install `git-credential-manager` to `/usr/local/bin`
>
> you can check by running: `which git-credential-manager`

### Run configuration for GCM and follow prompts

`git config --global credential.https://dev.azure.com.useHttpPath true`

`git-credential-manager configure`

### it should run without issue, but if it complains about not finding GCM executable you run:

`git config --global credential.helper "/usr/local/bin/git-credential-manager"`

re-run:

`git-credential-manager configure`

Then run:

`git config --global credential.credentialStore cache`

### Other git config items:

`git config --global user.name "Firstname Lastname"` ; #NOTE: use your first name and last name

`git config --global user.email "firstname.lastname@email.com"` ; #NOTE: use the email associated with github/git server

### Install `wslu`

`sudo apt-get install -y wslu`

wslu installs a command to open your default browser on your machine on windows side from Linux; try it with

`wslview https://google.com`

if successful:

`export BROWSER=/usr/bin/wslview`

### Test installation:

#### NOTE: pushd / popd are stack operational versions of cd command, handy for going between directories

`mkdir -p dev`

`pushd dev`

`git clone https://repo.url/repo.git repo-name`

`pushd repo-name`

##### Example python setup

`python -m venv .venv` ### this will create a virtualenv with installed python3 version 3.12.3

`source .venv/bin/activate` ### will put you into the virtualenv

`pip install -r requirements.txt`

`PYTHONPATH=. python ./path/to/script.py` ### this will run the script with the specified environment
