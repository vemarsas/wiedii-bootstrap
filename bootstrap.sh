#!/bin/bash

APP_NAME=wiedii
APP_USER=$APP_NAME
APP_GROUP=$APP_USER
APP_SUBDIR=$APP_NAME
APP_USER_HOME=/home/$APP_USER
APP_ROOT=$APP_USER_HOME/$APP_SUBDIR
APP_GIT="https://github.com/vemarsas/wiedii.git"
APP_BRANCH=main

install_conffiles() {
	cd $APP_ROOT
	cd doc/sysadm/examples
	install -bvC -m 440 etc/sudoers			/etc/
}

setup_initial() {
  apt-get update
  apt-get -y upgrade
  apt-get -y install sudo git-core openssh-server curl vim-nox mc

  adduser --system --shell /bin/bash --home $APP_USER_HOME --group $APP_USER && \
        echo "$APP_USER:$APP_USER" | chpasswd

  su - $APP_USER -c "
  if [ -d $APP_SUBDIR ]; then
    cd $APP_SUBDIR
    git remote set-url origin $APP_GIT
    git pull --ff-only origin $APP_BRANCH || true
  else
    git clone -b $APP_BRANCH $APP_GIT
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
      if id -u $APP_USER > /dev/null; then # ...but so show it here!
        echo 'Disabling/locking user "pi" (Raspberry) for security reasons.'
        echo "We have the user '$APP_USER' instead."
        passwd -l pi
      fi
    else
      echo "Change default password for security reasons"
      sudo passwd pi
    fi
    #clone groups from pi to APP_USER
    SRC=pi
    DEST=$APP_USER
    SRC_GROUPS=$(groups ${SRC})
    NEW_GROUPS=""
    i=0
    for gr in $SRC_GROUPS
      do
        if [ $i -gt 2 ]
        then
          if [ -z "$NEW_GROUPS" ];
          then NEW_GROUPS=$gr;
          else NEW_GROUPS="$NEW_GROUPS,$gr"; adduser $APP_USER $gr;
          fi
        fi
        (( i++ ))
      done
    echo "User $APP_USER added to the following groups: $NEW_GROUPS"
  fi

  # Apparently not enabled by default on Raspbian
  # TODO: make it optional in order to be security-paranoid?
  systemctl start ssh
  systemctl enable ssh
}

setup_core() {
  echo " Installing core functionality..."
  cd $APP_ROOT
  bash etc/scripts/platform/debian/setup.sh $APP_ROOT $APP_USER
}

run() {
  setup_initial | tee -a /var/log/${APP_NAME}_install.log
  setup_core    | tee -a /var/log/${APP_NAME}_install.log
}


run
