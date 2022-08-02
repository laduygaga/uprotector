# Installation

## Required
### apt
1. libssl-dev
### luarocks
1. lua5.1
2. cjson
3. luasec
4. lua-socket
### 
```
mkdir /tmp/rspamd
chown -hR _rspamd:_rspamd /tmp/rspamd
```
### GET token and cookie cho vào atchprotector.conf , có thể chạy cronjob	
```
cat >>/etc/hosts<<EOF
10.5.68.42 mysaferwall.com api.mysaferwall.com about.mysaferwall.com
EOF

get_token() {
	curl -kiX POST \
		'https://api.mysaferwall.com/v1/auth/login/' \
  		-H 'accept: application/json' \
  		-H 'Content-Type: application/json' \
  		-d '{
			"password": "namdz12345678",
			"username": "namdz"
		}'
}
```

```
apt install lua5.1
apt install luarocks 
luarocks  install lua-cjson
> ok =  /usr/local/lib/lua/5.1/cjson.so is existing else not ok
```
## Automatical
```
git clone https://github.com/laduygaga/uprotector
git checkout attachment-check
cd uprotector
./plug_and_play.sh
```

## Manual
- Copy `plugins.d/atchprotector.lua` module to your rspamd `plugins.d` directory
- Copy `local.d/atchprotector*` files to your rspamd `local.d` directory
- Copy or merge `local.d/groups.conf` content with your existing `local.d/groups.conf`
- Edit `local.d/uprotector.conf` to set enable/disable or config this plugin 
- Edit `local.d/atchprotector_group.conf` if you want to change scoring
- Copy `rspamd.conf.local` to your rspamd config folder (usually `/etc/rspamd`) or merge the content if you already use one.
- Restart rspamd

