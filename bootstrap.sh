#!/bin/bash

ONBOARD_USER=onboard
ONBOARD_GROUP=$ONBOARD_USER
ONBOARD_SUBDIR=wiedii-onboard
ONBOARD_USER_HOME=/home/$ONBOARD_USER
ONBOARD_ROOT=$ONBOARD_USER_HOME/$ONBOARD_SUBDIR
ONBOARD_GIT="https://github.com/vemarsas/wiedii-onboard.git"
ONBOARD_BRANCH=main

install_conffiles() {
	cd $ONBOARD_ROOT
	cd doc/sysadm/examples
	install -bvC -m 440 etc/sudoers			/etc/
}

setup_initial() {
  apt-get update
  apt-get -y upgrade
  apt-get -y install sudo git-core openssh-server curl vim-nox mc

  adduser --system --shell /bin/bash --home $ONBOARD_USER_HOME --group $ONBOARD_USER && \
        echo "$ONBOARD_USER:$ONBOARD_USER" | chpasswd

  su - $ONBOARD_USER -c "
  if [ -d $ONBOARD_SUBDIR ]; then
    cd $ONBOARD_SUBDIR
    git remote set-url origin $ONBOARD_GIT
    git pull --ff-only origin $ONBOARD_BRANCH || true
  else
    git clone -b $ONBOARD_BRANCH $ONBOARD_GIT
    # HTTPS passwords have been disabled by GitHub, allow at least to store tokens...
    git config --global credential.helper store
  fi
  "

  install_conffiles # including sudoers

  # Raspbian section

  # Disable pi user, with its insecure default password...
  if id -u pi 2> /dev/null; then # DO not show missing user error here...
    echo "Would you like to disable pi user? (y/n)"
    read answer
    if [[ $answer == y ]] ; then
      if id -u $ONBOARD_USER > /dev/null; then # ...but so show it here!
        echo 'Disabling/locking user "pi" (Raspberry) for security reasons.'
        echo "We have the user '$ONBOARD_USER' instead."
        passwd -l pi
      fi
    else
      echo "Change default password for security reasons"
      sudo passwd pi
    fi
    #clone groups from pi to ONBOARD_USER
    SRC=pi
    DEST=$ONBOARD_USER
    SRC_GROUPS=$(groups ${SRC})
    NEW_GROUPS=""
    i=0
    for gr in $SRC_GROUPS
      do
        if [ $i -gt 2 ]
        then
          if [ -z "$NEW_GROUPS" ];
          then NEW_GROUPS=$gr;
          else NEW_GROUPS="$NEW_GROUPS,$gr"; adduser $ONBOARD_USER $gr;
          fi
        fi
        (( i++ ))
      done
    echo "User $ONBOARD_USER added to the following groups: $NEW_GROUPS"
  fi

  # Apparently not enabled by default on Raspbian
  # TODO: make it optional in order to be security-paranoid?
  systemctl start ssh
  systemctl enable ssh
}

setup_core() {
  echo " Installing core functionality..."
  cd $ONBOARD_ROOT
  bash etc/scripts/platform/debian/setup.sh $ONBOARD_ROOT $ONBOARD_USER
}

run() {
  setup_initial | tee -a /var/log/mgyinstall.log
  setup_core    | tee -a /var/log/mgyinstall.log
}


run
