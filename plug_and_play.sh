#!/bin/bash

yes | cp -iv ./local.d/* /etc/rspamd/local.d/
yes | cp -iv ./plugins.d/atchprotector.lua /usr/share/rspamd/plugins/atchprotector.lua
yes | cp -iv ./rspamd.conf.local /etc/rspamd/

systemctl restart rspamd
