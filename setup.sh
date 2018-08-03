#!/bin/bash
#======================================================================================================================
#
#          FILE: setup.sh
#
#   DESCRIPTION: Install
#
#          BUGS: https://github.com/goodrain/rainbond-install/issues
#
#     COPYRIGHT: (c) 2018 by the Goodrain Delivery Team.
#
#       LICENSE: Apache 2.0
#       CREATED: 03/30/2018 10:49:37 AM
#======================================================================================================================
[[ $DEBUG ]] && set -x

export MAIN_CONFIG="/srv/pillar/rainbond.sls"

[ ! -d "/srv/pillar/" ] && (
    mkdir -p /srv/pillar/
    cp rainbond.yaml.default ${MAIN_CONFIG}
)

. scripts/common.sh

 # trap program exit
trap 'Exit_Clear; exit' SIGINT SIGHUP
clear

# -----------------------------------------------------------------------------
# checking the availability of system

Echo_Banner "Rainbond v$RBD_VERSION"

check_func(){
    Echo_Info "Check func."
    ./scripts/check.sh $@
}

init_config(){
    if [ ! -f $INIT_FILE ];then
        Echo_Info "Init rainbond configure."
        ./scripts/init_sls.sh && touch $INIT_FILE
    fi
}

install_func(){
    fail_num=0
    step_num=1
    all_steps=$(echo ${MANAGE_MODULES} | tr ' ' '\n' | wc -l)
    Echo_Info "will install manage node.It will take 15-30 minutes to install"
  
    for module in ${MANAGE_MODULES}
    do
        if [ "$module" = "image" ];then
            Echo_Info "Start install $module(step: $step_num/$all_steps), it will take 8-15 minutes "
            Echo_Info "This step will pull/load all docker images"
        else
            Echo_Info "Start install $module(step: $step_num/$all_steps) ..."
        fi
        if ! (salt "*" state.sls $module);then
            ((fail_num+=1))
            break
        fi
        ((step_num++))
        sleep 1
    done

    if [ "$fail_num" -eq 0 ];then
      if $( grep 'install-type: online' /srv/pillar/rainbond.sls >/dev/null );then
        REG_Status || return 0
        systemctl restart node
      fi
      uuid=$(salt '*' grains.get uuid | grep "-" | awk '{print $1}')
        notready=$(grctl  node list | grep $uuid | grep false)
        if [ "$notready" != "" ];then
            grctl node up $uuid
        fi
        Echo_Info "install successfully"
        public_ip=$(yq r /srv/pillar/rainbond.sls master-public-ip)
        private_ip=$(yq r /srv/pillar/rainbond.sls master-private-ip)
        
        if [ ! -z "$public_ip" ];then
            Echo_Banner "http://${public_ip}:7070"
        else
            Echo_Banner "http://${private_ip}:7070"
        fi
    else
        Echo_Info "install help"
        Echo_Info "https://www.rainbond.com/docs/stable/operation-manual/trouble-shooting/install-issue.html"
        exit 1
    fi
}

case $1 in
    *)
        check_func && init_config ${1:-online} && install_func ${@:2}
    ;;
esac
