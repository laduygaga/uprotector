#!/bin/bash

yes | cp -iv ./local.d/* /etc/rspamd/local.d/
yes | cp -iv ./plugins.d/uprotector.lua /usr/share/rspamd/plugins/uprotector.lua
cat ./rspamd.conf.local >> /etc/rspamd/rspamd.conf.local

systemctl restart rspamd
