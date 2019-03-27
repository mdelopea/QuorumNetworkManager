#!/bin/bash

#TODO: Add version check for nodejs as well

sudo apt-get update
sudo apt-get install -y build-essential libssl-dev git curl

# Expected versions
QUORUM_NETWORK_MANAGER_VERSION='0.8.1-beta'
EXPECTED_NODEJS_VERSION='8.x'
EXPECTED_GO_VERSION='1.10.3'
EXPECTED_QUORUM_COMMIT_HASH='df4267a25637a5497a3db9fbde4603a3dcd6aa14'
EXPECTED_QUORUM_VERSION='2.0.1'
EXPECTED_CONSTELLATION_VERSION='0.3.2'

# Install NodeJS
NODEJS_VERSION=$(node --version)
if [[ $NODEJS_VERSION = "" ]]
then
  curl -sL https://deb.nodesource.com/setup_${EXPECTED_NODEJS_VERSION} | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# Checking GO version
echo 'Checking go version, if not found will install'
GO_PATH=$(which go)
if [[ $GO_PATH != "" ]]
then
  GO_VERSION=$(go version)
  if [[ $GO_VERSION != "go version go$EXPECTED_GO_VERSION linux/amd64" ]] && [[ $GO_VERSION != "" ]]
  then
    echo "go version other than $EXPECTED_GO_VERSION detected, please see v$QUORUM_NETWORK_MANAGER_VERSION release notes"
    echo "current: $GO_VERSION"
    echo 'exiting...'
    exit
  fi
fi

# Install GO
GO_PATH=$(which go)
if [[ $GO_PATH = "" ]]
then
  echo 'Installing go...'
  wget https://storage.googleapis.com/golang/go${EXPECTED_GO_VERSION}.linux-amd64.tar.gz
  tar -xf go${EXPECTED_GO_VERSION}.linux-amd64.tar.gz
  sudo cp -r go/ /usr/local/
  rm -rf go/ go${EXPECTED_GO_VERSION}.linux-amd64.tar.gz
  DETECTED_GO_PATH=$(which go)
  if [[ $DETECTED_GO_PATH = "" ]]
  then
    echo "export GOROOT=/usr/local/go" >> ~/.bashrc
    echo "export GOPATH=$HOME/projects/go" >> ~/.bashrc
    echo "PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/projects/go
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
  fi
  echo "Installed go version $EXPECTED_GO_VERSION"
else
  echo 'Skipped installing go'
fi

# Detect/move/remove/update/install geth/quorum
GETH_PATH=$(which geth)
if [[ $GETH_PATH != "" ]]
then
  GETH_TYPE=$(geth version | sed -n '4,4p' | sed 's/ /\n/g' | head -1)
  if [[ $GETH_TYPE != "Quorum" ]] # currently detected geth is not quorum
  then
    if [[ $GETH_PATH = '/usr/bin/geth' ]]
    then
      sudo mv /usr/bin/geth /usr/bin/normalGeth
    fi
  fi
  QUORUM_COMMIT=$(geth version | sed -n '3,3p' | sed 's/ /\n/g' | tail -1)
  if [[ $QUORUM_COMMIT != $EXPECTED_QUORUM_COMMIT_HASH ]] # incorrect version of quorum detected
  then
    if [[ -d "quorum" ]]
    then
      QUORUM_INSTALLED_DIR=${GETH_PATH%/build/bin/geth}
      QUORUM_TARGET_DIR=$(readlink -f quorum)
      if [[ $QUORUM_TARGET_DIR = $QUORUM_INSTALLED_DIR ]]
      then
        echo 'Updating Quorum...'
        cd quorum/
        git fetch --tags
        git checkout v$EXPECTED_QUORUM_VERSION
        make all
        echo "Updated Quorum to $EXPECTED_QUORUM_VERSION"
        cd ..
      else
        echo "Skipping Quorum update: Detected quorum not installed in $QUORUM_TARGET_DIR - human intervention required"
      fi
    else
      echo "Quorum version other than $EXPECTED_QUORUM_VERSION detected and/or installed in unknown location - human intervention required"
      echo "Current: $QUORUM_COMMIT"
      echo 'Exiting...'
      exit
    fi
  fi
else
  if [[ ! -d "quorum" ]]
  then
    echo 'Installing Quorum...'
    git clone https://github.com/jpmorganchase/quorum.git
    cd quorum/
    git fetch --tags
    git checkout v$EXPECTED_QUORUM_VERSION
    make all
    DETECTED_GETH_PATH=$(which geth)
    if [[ $DETECTED_GETH_PATH = "" ]]
    then
      echo "PATH=\$PATH:"$PWD/build/bin >> ~/.bashrc
      export PATH=$PWD/build/bin:$PATH
      source ~/.bashrc
    fi
    cd ..
    echo "Installed Quorum $EXPECTED_QUORUM_VERSION"
  else
    echo 'Skipped installing Quorum'
  fi
fi

# Checking constellation version
echo 'Checking constellation version, if not found will install'
CONSTELLATION_PATH=$(which constellation-node)
if [[ $CONSTELLATION_PATH != "" ]]
then 
  CONSTELLATION_VERSION=$(constellation-node --version)
  if [[ $CONSTELLATION_VERSION != "Constellation Node $EXPECTED_CONSTELLATION_VERSION" ]] && [[ $CONSTELLATION_VERSION != "" ]]
  then
    echo "constellation version other than $EXPECTED_CONSTELLATION_VERSION detected, please see v$QUORUM_NETWORK_MANAGER_VERSION release notes"
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
  sudo apt-get install -y libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev
  wget https://github.com/jpmorganchase/constellation/releases/download/v${EXPECTED_CONSTELLATION_VERSION}/constellation-${EXPECTED_CONSTELLATION_VERSION}-ubuntu1604.tar.xz -O constellation-${EXPECTED_CONSTELLATION_VERSION}-ubuntu1604.tar.xz
  tar -xf constellation-${EXPECTED_CONSTELLATION_VERSION}-ubuntu1604.tar.xz
  rm constellation-${EXPECTED_CONSTELLATION_VERSION}-ubuntu1604.tar.xz
  chmod +x constellation-${EXPECTED_CONSTELLATION_VERSION}-ubuntu1604/constellation-node
  DETECTED_CONSTELLATION_PATH=$(which constellation-node)
  sudo ln -s /usr/lib/x86_64-linux-gnu/libsodium.so.23.1.0 /usr/lib/libsodium.so.18
  if [[ $DETECTED_CONSTELLATION_PATH = "" ]]
  then
    echo "PATH=\$PATH:"$PWD/constellation-${EXPECTED_CONSTELLATION_VERSION}-ubuntu1604 >> ~/.bashrc
    export PATH=$PWD/constellation-${EXPECTED_CONSTELLATION_VERSION}-ubuntu1604:$PATH
    source ~/.bashrc
  fi
  cd ..
  echo "Installed Constellation ${EXPECTED_CONSTELLATION_VERSION}"
else
  echo 'Skipped installing Constellation'
fi

# Installing istanbul-tools
OLD_GOPATH=$GOPATH
echo 'Installing Istanbul-tools...'
GOPATH=$PWD/istanbul-tools go get github.com/getamis/istanbul-tools/cmd/istanbul
DETECTED_ISTANBUL_PATH=$(which istanbul)
if [[ $DETECTED_ISTANBUL_PATH = "" ]]
then
  echo "PATH=\$PATH:"$PWD/istanbul-tools/bin >> ~/.bashrc
  echo 'Installed Istanbul-tools'
  source ~/.bashrc
fi
GOPATH=$OLD_GOPATH

# Cloning the QuorumNetworkManager repo
if [[ ! -d "QuorumNetworkManager" ]]
then 
  echo 'Cloning and installing QuorumNetworkManager...'
  git clone https://github.com/consensys/QuorumNetworkManager.git
  cd QuorumNetworkManager/
  git checkout v${QUORUM_NETWORK_MANAGER_VERSION}
  npm install
  echo "Cloned and installed QuorumNetworkManager v$QUORUM_NETWORK_MANAGER_VERSION"
else
  echo 'Skipped cloning and installing QuorumNetworkManager'
fi
