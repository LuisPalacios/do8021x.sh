# wpa_supplicant CLI start/stop script

The do801x.sh script will run `wpa_supplicant` without storing user/password for a
wired 802.1x connection. Notice that the user/password will only exist in memory. 
This is a CLI solution, no GUI.

### Script

You can find the script here: [8021x.sh](https://raw.githubusercontent.com/LuisPalacios/do8021x.sh/master/do8021x.sh)

### Install

Copy to your prefered place in the PATH and don't forget to edit the file and change the name of your interface under `export INTERFACE=`

```
$ sudo cp do8021x.sh /usr/bin
```


### Start

```
$ sudo /usr/bin/do8021x.sh
```

### Stop

```
$ sudo /usr/bin/do8021x.sh -k
```
