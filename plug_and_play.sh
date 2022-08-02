#!/bin/bash

yes | cp -iv ./local.d/atchprotector.conf /etc/rspamd/local.d/
yes | cp -iv ./local.d/atchprotector_group.conf /etc/rspamd/local.d/
cat ./local.d/groups.conf >> /etc/rspamd/local.d/groups.conf
yes | cp -iv ./plugins.d/atchprotector.lua /usr/share/rspamd/plugins/atchprotector.lua
cat ./rspamd.conf.local >> /etc/rspamd/rspamd.conf.local

systemctl restart rspamd
