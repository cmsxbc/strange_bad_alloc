#/bin/bash

if [[ ! -e /tmp/sde.tar.xz ]];then
    curl -o /tmp/sde.tar.xz https://downloadmirror.intel.com/788820/sde-external-9.27.0-2023-09-13-lin.tar.xz
fi
mkdir /tmp/sde
tar -xvf /tmp/sde.tar.xz -C /opt/
ln -s /opt/sde* /opt/sde
ln -s /opt/sde/sde64 /usr/bin/sde
