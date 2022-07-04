### Installation

- Copy `plugins.d/uprotector.lua` module to your rspamd `plugins.d` directory
- Copy `local.d/uprotector*` files to your rspamd `local.d` directory
- Copy or merge `local.d/groups.conf` content with your existing `local.d/groups.conf`
- Edit `local.d/uprotector.conf` to set your Cyren gateway url
- Edit `local.d/uprotector_group.conf` if you want to change scoring
- Copy `rspamd.conf.local` to your rspamd config folder (usually `/etc/rspamd`) or merge the content if you already use one.
- Restart rspamd

