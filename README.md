## Physical machine

You don't even need to clone this repo.

Install Debian (or Raspbian etc.) in your machine.

Login and become root.

Then run:

```
bash -c "$(wget -O - https://raw.githubusercontent.com/vemarsas/wiedii-bootstrap/main/bootstrap.sh)"
```

## Virtual machine

See [README.Vagrant.md](README.Vagrant.md).

## Development / alt branches

As root:

```
wget https://raw.githubusercontent.com/vemarsas/wiedii-bootstrap/<MY_BOOTSTRAP_BRANCH>/bootstrap.sh

bash bootstrap.sh MY_APP_BRANCH
```
