# Installation

## Automatical
```
git clone https://github.com/laduygaga/uprotector
cd uprotector
./plug_and_play
```

## Manual
- Copy `plugins.d/uprotector.lua` module to your rspamd `plugins.d` directory
- Copy `local.d/uprotector*` files to your rspamd `local.d` directory
- Copy or merge `local.d/groups.conf` content with your existing `local.d/groups.conf`
- Edit `local.d/uprotector.conf` to set enable/disable or config this plugin 
- Edit `local.d/uprotector_group.conf` if you want to change scoring
- Copy `rspamd.conf.local` to your rspamd config folder (usually `/etc/rspamd`) or merge the content if you already use one.
- Restart rspamd

