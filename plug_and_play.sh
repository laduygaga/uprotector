#!/bin/bash

yes | cp -iv ./local.d/* /etc/rspamd/local.d/
yes | cp -iv ./plugins.d/uprotector.lua /usr/share/rspamd/plugins/uprotector.lua
yes | cp -iv ./rspamd.conf.local /etc/rspamd/

systemctl restart rspamd
