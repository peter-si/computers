# Ansible playbook to bootstrap Arch linux


This is an [Ansible][1] playbook meant to provision a personal machine running
[Arch Linux][2]. It is intended to run locally on a fresh Arch install (ie,
taking the place of any [post-installation][3]), but due to Ansible's
idempotent nature it may also be run on top of an already configured machine.
Contains `disk-bootstrap.sh` which will partition given disk, encrypt and bootstrap
btrfs with snapshots. Then you can run this ansible playbook to install Arch linux ready to use.

**Note:** If you would like to try recreating all the tasks that are currently
included in the ansible playbook, through a VM, you would need a disk of at least
**16GB** in size.

For best experience this should be added to live usb

```bash
cp -r /usr/share/archiso/configs/releng ~/archlive
git clone git@github.com:peter-si/arch-ansible.git ~/archlive/airootfs/install
cd ~/archlive/airootfs/install && git submodule update --recursive --remote && cd ~
sudo mkarchiso -v -w /tmp/archiso-tmp ~/archlive
sudo dd bs=4M status=progress oflag=sync if="location of iso" of=/dev/sdd
```

You should also add .ssh folder with keys to download dotfiles. These will be automatically installed on new pc

```bash
cp -r ~/.ssh ~/archlive/airootfs/install
```

**Note:** Don't leave your unencrypted private keys in live usb

To set correct perimissions add

```
  ["/install/clean-disk.sh"]="0:0:755"
  ["/install/disk-bootstrap.sh"]="0:0:755"
  ["/install/root-pass.sh"]="0:0:755"
  ["/install/.ssh/id_rsa"]="0:0:600"
```

add some additional packages to install

```
git
bitwarden-cli
```

into your `archlive/profiledef.sh`

## Running

If you are on wifi connect to internet via `iwctl`

```iwctl
station wlan0 connect name_of_network
```

If you have password protected ssh key, you must first remove the password

```bash
ssh-keygen -p -f /install/.ssh/id_rsa
```

Navigate to `/install` and set up disks with following command (and follow prompts)

```bash
./disk-bootstrap.sh -l {ansible_host} /dev/sdX
```

There some special cases:
* installing side by side other system (you need to manually remove disk partitions when reinstalling): `./disk-bootstrap.sh -n -l {ansible_host} /dev/sdX`
* just installing (retry, when ansible fails installation): `./disk-bootstrap.sh -n -i -l {ansible_host} /dev/sdX`

### Finishing installation

If needed connect to wifi using

```bash
nmcli d wifi c name_of_network password SecretPassword
```

To [check iptables dropped packets](https://wiki.archlinux.org/index.php/iptables#Logging) use

```bash
journalctl -fk | grep "IN=.*OUT=.*"
```

When working on remote machines from home network use **home** inventory e.g. `ansible-playbook playbook.yaml -l home-server -i remote`

## Dotfiles

Ansible expects that the user wishes to clone dotfiles via the git repository
specified via the `user.dotfiles` variable and install them with [yadm][5].

## SSH

By default, Ansible will attempt to install the private SSH key for the user. The
key should be available at the path specified in the `ssh_user_key` variable.
Removing this variable will cause the key installation task to be skipped.

### SSHD

If `ssh_enable_sshd` is set to `True` the [systemd socket service][4] will be
enabled. By default, sshd is configured but not enabled.


## MAC Spoofing

By default, the MAC address of all network interfaces is spoofed at boot,
before any network services are brought up. This is done with [macchiato][11],
which uses legitimate OUI prefixes to make the spoofing less recognizable.

MAC spoofing is desirable for greater privacy on public networks, but may be
inconvenient on home or corporate networks where a consistent (if not real) MAC
address is wanted for authentication. To work around this, allow `macchiato` to
randomize the MAC on boot, but tell NetworkManager to clone the real (or a fake
but consistent) MAC address in its profile for the trusted networks. This can
be done in the GUI by populating the "Cloned MAC address" field for the
appropriate profiles, or by setting the `cloned-mac-address` property in the
profile file at `/etc/NetworkManager/system-connections/`.

Spoofing may be disabled entirely by setting the `network.spoof_mac` variable
to `False`.

## Trusted Networks

The trusted network framework provided by [nmtrust][12] is leveraged to start
certain systemd units when connected to trusted networks, and stop them
elsewhere.

This helps to avoid leaking personal information on untrusted networks by
ensuring that certain network tasks are not running in the background.
Currently, this is used for mail syncing (see the section below on Syncing and
Scheduling Mail), Tarsnap backups (see the section below on Scheduling
Tarsnap), BitlBee (see the section below on BitlBee), and git-annex (see the
section below on git-annex).

Trusted networks are defined using their NetworkManager UUIDs, configured in
the `network.trusted_uuid` list. NetworkManager UUIDs may be discovered using
`nmcli con`.

[1]: http://www.ansible.com
[2]: https://www.archlinux.org
[3]: https://wiki.archlinux.org/index.php/Installation_guide#Post-installation
[4]: https://wiki.archlinux.org/index.php/Secure_Shell#Managing_the_sshd_daemon
[5]: https://yadm.io/
[6]: https://aur.archlinux.org
[7]: https://github.com/pigmonkey/ansible-aur
[8]: https://github.com/Jguer/yay
[9]: https://wiki.archlinux.org/index.php/AUR_helpers
[10]: https://firejail.wordpress.com/
[11]: https://github.com/EtiennePerot/macchiato
[12]: https://github.com/pigmonkey/nmtrust
