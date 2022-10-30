Install Vagrant -- https://www.vagrantup.com/.

Then run

```bash
vagrant up
```

The above is equivalent to:

```bash
vagrant up mgy
```

You can start a "client" VM, connected "behind" Margay via virtualized internal network:
```bash
vagrant up client
```
`eth0` in the client is connected to `eth1` in Margay.

You can also fire up a second Margay "downstream":
```bash
vagrant up mgy_downstr
```
`eth1` in `mgy_downstr` is connected to `eth2` in `mgy`.

The client VM will show the VBox GUI, you will see a graphical login.
Enter with credentials vagrant:vagrant, then right-click
and open Web Browser (or Terminal etc.)

The same argument `mgy`, `mgy_downstr`, or `client` holds for
other Vagrant commands: provision, halt, suspend, destroy etc.
(see documentation on the Vagrant website).

### Margay setup

At this point Margay is not setuo yet.

Please refer to: https://github.com/vemarsas/margay#readme.

It's the same installation procedure you would use on real hardware!

### Synced folder

We do not use it. Use sshfs or a plugin in your editor/IDE to connect to the machine `/home/onboard`
and edit / git push etc. from the host.

### Very optional Vagrant tweaks

#### Proxy

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

### After installation

Margay server will be available at

* http://localhost:4567  (4568 for `mgy_downstr`)
* https://localhost:4443 (4444 )

The default credentials are `admin`:`admin`.
