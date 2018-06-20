#!/bin/bash

#TODO: Add version check for nodejs as well
#TODO: extract versions to variables

sudo apt-get update
sudo apt-get install -y build-essential libssl-dev git curl

# Install NodeJS
NODEJS_VERSION=$(node --version)
if [[ $NODEJS_VERSION = "" ]]
then
  curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# Checking GO version
echo 'Checking go version, if not found will install'
GO_PATH=$(which go)
if [[ $GO_PATH != "" ]]
then
  GO_VERSION=$(go version)
  if [[ $GO_VERSION != 'go version go1.10.3 linux/amd64' ]] && [[ $GO_VERSION != "" ]]
  then
    echo 'go version other than 1.10.3 detected, please see v0.8.0 release notes'
    echo 'current:' $GO_VERSION
    echo 'exiting...'
    exit
  fi
fi

# Install GO
GO_PATH=$(which go)
if [[ $GO_PATH = "" ]]
then
  echo 'Installing go...'
  wget https://storage.googleapis.com/golang/go1.10.3.linux-amd64.tar.gz
  tar -xf go1.10.3.linux-amd64.tar.gz
  sudo cp -r go/ /usr/local/
  rm -rf go/ go1.10.3.linux-amd64.tar.gz
  echo "export GOROOT=/usr/local/go" >> ~/.bashrc
  echo "export GOPATH=$HOME/projects/go" >> ~/.bashrc
  echo "PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
  export GOROOT=/usr/local/go
  export GOPATH=$HOME/projects/go
  export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
  echo 'Installed go version 1.10.3'
else
  echo 'Skipped installing go'
fi

# Moving geth
GETH_PATH=$(which geth)
if [[ $GETH_PATH = '/usr/bin/geth' ]]
then
  sudo mv /usr/bin/geth /usr/bin/normalGeth
fi

# Cloning the quorum repo
if [ ! -d "quorum" ]
then
  echo 'Installing Quorum...'
  git clone https://github.com/jpmorganchase/quorum.git
  cd quorum/
  git fetch --tags
  git checkout v2.0.2
  make all
  echo "PATH=\$PATH:"$PWD/build/bin >> ~/.bashrc
  source ~/.bashrc
  export PATH=$PWD/build/bin:$PATH
  cd ..
  echo 'Installed Quorum 2.0.2'
else
  echo 'Skipped installing Quorum'
fi

# Checking constellation version
echo 'Checking constellation version, if not found will install'
CONSTELLATION_PATH=$(which constellation-node)
if [[ $CONSTELLATION_PATH != "" ]]
then 
  CONSTELLATION_VERSION=$(constellation-node --version)
  if [[ $CONSTELLATION_VERSION != 'Constellation Node 0.3.2' ]] && [[ $CONSTELLATION_VERSION != "" ]]
  then
    echo 'constellation version other than 0.3.2 detected, please see v0.8.0 release notes'
    echo 'current:' $CONSTELLATION_VERSION
    echo 'exiting...'
    exit
  fi
fi

# Installing constellation
CONSTELLATION_PATH=$(which constellation-node)
if [[ $CONSTELLATION_PATH = "" ]]
then
  echo 'Installing Constellation...'
  mkdir -p constellation && cd constellation/
  sudo apt-get install libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev
  wget https://github.com/jpmorganchase/constellation/releases/download/v0.3.2/constellation-0.3.2-ubuntu1604.tar.xz -O constellation-0.3.2-ubuntu1604.tar.xz
  tar -xf constellation-0.3.2-ubuntu1604.tar.xz
  rm constellation-0.3.2-ubuntu1604.tar.xz
  chmod +x constellation-0.3.2-ubuntu1604/constellation-node
  echo "PATH=\$PATH:"$PWD/constellation-0.3.2-ubuntu1604 >> ~/.bashrc
  source ~/.bashrc
  export PATH=$PWD/constellation-0.3.2-ubuntu1604:$PATH
  cd ..
  echo 'Installed Constellation 0.3.2'
else
  echo 'Skipped installing Constellation'
fi

# Installing istanbul-tools
OLD_GOPATH=$GOPATH
echo 'Installing Istanbul-tools...'
GOPATH=$PWD/istanbul-tools go get github.com/getamis/istanbul-tools/cmd/istanbul
echo "PATH=\$PATH:"$PWD/istanbul-tools/bin >> ~/.bashrc
echo 'Installed Istanbul-tools'
source ~/.bashrc
GOPATH=$OLD_GOPATH

# Cloning the QuorumNetworkManager repo
if [ ! -d "QuorumNetworkManager" ]
then 
  echo 'Cloning and installing QuorumNetworkManager...'
  git clone https://github.com/consensys/QuorumNetworkManager.git
  cd QuorumNetworkManager/
  #git checkout v0.7.5-beta
  npm install
  echo 'Cloned and installed QuorumNetworkManager'
else
  echo 'Skipped cloning and installing QuorumNetworkManager'
fi
