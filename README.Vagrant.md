## Basics

* Clone this repo
* Cd into it
* Install Vagrant -- https://www.vagrantup.com/
* `vagrant up`

## VMs

The above is equivalent to:

```bash
vagrant up wiedii
```

You can start a "client" VM, connected "behind" Wiedii via virtualized internal network:
```bash
vagrant up client
```
`eth0` in the client is connected to `eth1` in Wiedii.

You can also fire up a second Wiedii "downstream":
```bash
vagrant up wiedii_downstr
```
`eth1` in `wiedii_downstr` is connected to `eth2` in `wiedii`.

The client VM will show the VBox GUI, you will see a graphical login.
Enter with credentials vagrant:vagrant, then right-click
and open Web Browser (or Terminal etc.)

The same argument `wiedii`, `wiedii_downstr`, or `client` holds for
other Vagrant commands: provision, halt, suspend, destroy etc.
(see documentation on the Vagrant website).

## Wiedii setup

At this point Wiedii is not setup yet.

To setup Wiedii (if not done already):
```bash
vagrant ssh <wiedii OR wiedii_downstr>
sudo -i
bash -c "$(wget -O - https://raw.githubusercontent.com/vemarsas/wiedii-bootstrap/main/bootstrap.sh)"
```
That's the same installation procedure you would use on real hardware!

### If you are developing bootstrap.sh itself and want to test it

You can find (and run) it as `/vagrant/bootstrap.sh` from within the guest. (As root).

## After Wiedii setup

### Upstream Wiedii
* SSH: port 2222 @localhost, user: "wiedii", password: "wiedii"
* Wiedii web: http://localhost:4567 or https://localhost:4443, "admin", "admin"

### Downstream Wiedii
* SSH: port 2223 @localhost, user: "wiedii", password: "wiedii"
* Wiedii web: http://localhost:4568 or https://localhost:4444, "admin", "admin"

See also `COMMON_MESSAGE` (and *`.vm.post_up_message`) in [Vagrantfile](Vagrantfile).

## Very optional Vagrant tweaks

### Proxy

If you install the vagrant-proxyconf plugin,
you also set proxy environment variables if you want to use a proxy
for downloading packages during provisioning etc.

See https://github.com/tmatilai/vagrant-proxyconf#environment-variables for more.

Suggested values (from the host!) are

```bash
VAGRANT_HTTP_PROXY=http://10.0.2.2:8123
VAGRANT_HTTPS_PROXY=http://10.0.2.2:8123
```
if, for example, you use polipo with default config
(10.0.2.2 is the default gateway for vbox NAT interface in the vm).

Beware this may conflict with captive portal in the client, as browsers will then use the proxy
and therefore circumvent the captive portal (depending on the configuration).
