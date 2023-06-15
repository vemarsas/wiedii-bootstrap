# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'pp'

DEBIAN_BOX = "debian/bullseye64"
COMMON_MESSAGE = "To setup Wiedii (if not done already):
  vagrant ssh <wiedii OR wiedii_downstr>
  sudo -i
  bash -c \"$(wget -O - https://raw.githubusercontent.com/vemarsas/wiedii-bootstrap/main/bootstrap.sh)\"
"
ENABLE_PASSWD = <<-END
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  systemctl restart sshd.service
END


# Ex. allow_promisc wiedii, [2, 3, 4], :allow_vms
# (NIC ID=1 is generally the default/NAT interface)
# The third arg may also be :allow_all or :deny
def allow_promisc(vmcfg, nicids, allow=:allow_vms)
  vmcfg.vm.provider "virtualbox" do |vb|
    nicids.each do |i|
      vb.customize ["modifyvm", :id, "--nicpromisc#{i}", allow.to_s.gsub('_', '-')]
    end
  end
end


=begin
                                             TOPOLOGY

                                            default/NAT
                                                |
                                              (eth0)
  --------                                    -----
 | CLIENT |---default(vlan1?)_access---(eth1)| WIEDII |(eth3)---vlan2_access
  --------                                    -----
                                              (eth2)
                                                |
                                            vlan_trunk (vlans 1, 2)
                                                |
                                              (eth1)
                                            -------------
                       default/NAT---(eth0)| WIEDII_DOWNSTR |
                                            -------------
                                            (eth2) (eth3)
                                              |       |
                            downstr_vlan_1_access    downstr_vlan_2_access

  Of course, VLAN IDs 1, 2 are purely conventional/examples: they are not enforced in this Vagrantfile.

  A simpler topology with no VLANs will be just WIEDII and CLIENT (e.g. to test Raidus/Chilli and no 802.1Q involved).
  That was indeed the original design.
=end


Vagrant.configure("2") do |config|
  config.vm.define "wiedii", primary: true do |wiedii|

    wiedii.vm.box = DEBIAN_BOX

    wiedii.vm.hostname = "wiedii"

    wiedii.vm.synced_folder ".", "/vagrant", disabled: true

    wiedii.vm.network "forwarded_port", guest: 22,   host: 2222
    wiedii.vm.network "forwarded_port", guest: 4567, host: 4567
    wiedii.vm.network "forwarded_port", guest: 443,  host: 4443

    # NIC #1 is the default NAT interface, with forwarded ports above

    # NIC #2
    wiedii.vm.network "private_network",  # may also be used as vlan 1 access
      auto_config: false, # or will reset what wiedii-persist has configured on the interface
      virtualbox__intnet: "default_access"

    # NIC #3
    wiedii.vm.network "private_network",
      auto_config: false, # or will reset what wiedii-persist has configured on the interface
      virtualbox__intnet: "vlan_trunk"

    # NIC #4
    wiedii.vm.network "private_network",
      auto_config: false, # or will reset what wiedii-persist has configured on the interface
      virtualbox__intnet: "vlan2_access"

    # If we ever want bridges to work...
    allow_promisc wiedii, [2, 3, 4], :allow_vms

    wiedii.vm.provision "shell", inline: ENABLE_PASSWD

    wiedii.vm.post_up_message = [
      COMMON_MESSAGE,
      'After Wiedii setup:',
      'SSH: port 2222 @localhost, user: "onboard", password: "onboard"',
      'Wiedii web: http://localhost:4567 or https://localhost:4443'
    ].join("\n")
  end

  config.vm.define "wiedii_downstr", autostart: false do |wiedii_downstr|  # downstream switch, currently a wiedii, could be an Arista, Cisco, etc.

    wiedii_downstr.vm.box = DEBIAN_BOX

    wiedii_downstr.vm.hostname = "wiedii-downstr"

    wiedii_downstr.vm.synced_folder ".", "/vagrant", disabled: true

    wiedii_downstr.vm.network "forwarded_port",  guest: 22,   host: 2223
    wiedii_downstr.vm.network "forwarded_port",  guest: 4567, host: 4568
    wiedii_downstr.vm.network "forwarded_port",  guest: 443,  host: 4444

    # NIC #1 is the default NAT interface, with forwarded ports above

    # NIC #2
    wiedii_downstr.vm.network "private_network",
      auto_config: false, # or will reset what wiedii-persist has configured on the interface
      virtualbox__intnet: "vlan_trunk"

    # NIC #3
    wiedii_downstr.vm.network "private_network",
      auto_config: false, # or will reset what wiedii-persist has configured on the interface
      virtualbox__intnet: "downstr_vlan_1_access"

    # NIC #4
    wiedii_downstr.vm.network "private_network",
      auto_config: false, # or will reset what wiedii-persist has configured on the interface
      virtualbox__intnet: "downstr_vlan_2_access"

    allow_promisc wiedii_downstr, [2, 3, 4], :allow_vms

    wiedii_downstr.vm.provision "shell", inline: ENABLE_PASSWD

    wiedii_downstr.vm.post_up_message = [
      COMMON_MESSAGE,
      'After Wiedii setup:',
      'SSH: port 2223 @localhost, user: "onboard", password: "onboard"',
      'Wiedii web: http://localhost:4568 or https://localhost:4444'
    ].join("\n")
  end

  # The client machine may be any OS, but for economy of storage and download time,
  # it's based on the same base box.
  config.vm.define "client", autostart: false do |wiediic|
    wiediic.vm.box = DEBIAN_BOX
    wiediic.vm.hostname = "wiediiclient"
    wiediic.vm.network "private_network",
      auto_config: false,
          # Vagrant auto_config would otherwise mess things up here,
          # modifying /etc/network/interfaces so to remove the default gw from
          # wiedii (ordinary DHCP or chillispot).
      virtualbox__intnet: "default_access"
    wiediic.vm.provider "virtualbox" do |vb|
      vb.gui = true
      # https://stackoverflow.com/a/24253435
      vb.customize ["modifyvm", :id, "--vram", "16"]
    end
    wiediic.vm.provision "shell", inline: <<-EOF
      # restore default VBox NAT interface networking (if it has been disabled previously to use wiedii-connected interface eth1)
      ip link set up dev eth0
      # ASSUME dhclient is the dhcp client
      if (ps aux | grep dhclient | grep eth0 | grep -v grep); then
        if (ip route | grep default | grep -v grep); then
          ip route replace default via 10.0.2.2 dev eth0
        else
          ip route add default via 10.0.2.2 dev eth0
        fi
      else
        dhclient eth0
      fi

      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get -y upgrade
      apt-get install -y lightdm openbox lxterminal psmisc firefox-esr
      systemctl start lightdm

      # Remove default Internet connection, it will use the second interface behind
      # wiedii (now that provisioning is done and software downloaded).

      cat > /etc/network/interfaces <<EOFF
# Auto-generated by a custom Vagrant provisioner for wiedii client.

# source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# Default VBox NAT
auto eth0
iface eth0 inet dhcp
pre-up sleep 2
post-up ip route del default dev \\$IFACE || true

# Interface connected to Wiedii
auto eth1
iface eth1 inet dhcp
EOFF

    systemctl restart networking

    echo "vagrant:vagrant" | chpasswd

    EOF
  end
end
