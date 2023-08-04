# XivMitmLatencyMitigator in a Docker container

Please visit official [XivMitmLatencyMitigator](https://github.com/Soreepeong/XivMitmLatencyMitigator) for more information.

### What is this?

This is a Docker container version of XivMitmLatencyMitigator. It aims for easy and super fast deployment on any Linux machine without a need to install required library and iptables config. It also auto start on boot, you don't need to create a custom service by yourself. All of this can be achieve with just 1 command!

* [Requirements](https://github.com/bankjaneo/XivMitmDocker#requirements)
* [Basic usage](https://github.com/bankjaneo/XivMitmDocker#basic-usage)
* [Advance usage](https://github.com/bankjaneo/XivMitmDocker#advance-usage)
* [FAQ](https://github.com/bankjaneo/XivMitmDocker#faq)

### Changelog

* Apr 6, 2023 - Support custom definitions.json URL with environment variable `DEFINITIONS_URL`.
* Mar 10, 2023 - Change ffxiv.exe to ffxiv_dx11.exe to support 6.35.
* Jun 28, 2023 - Cleanup docker logs and update ffxiv_dx11.exe to 6.41.
* Jul 21, 2023 - Update ffxiv_dx11.exe to 6.45.
* Aug 3, 2023 - Add support for argument --extra-delay, --measure-ping, --nftables and set default --measure-ping to false (prior versions default to true).

-----

### Requirements

A Linux with IPv4 forwarding enabled and Docker Engine installed.

#### Enable IPv4 forwarding.

You need to edit `/etc/sysctl.conf` by uncommenting the line (remove # in front of it) that contains `net.ipv4.ip_forward=1` and `reboot` your Linux or you can run this one-line command.

```
sudo sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/" /etc/sysctl.conf && sudo sysctl -p && sudo reboot
```

#### Docker Engine installation.

If you are new to Docker, you can just copy and run the following command to install both `docker` and `docker-compose`. If command below doesn't work or you want to figure by yourself, you can try visit [here](https://docs.docker.com/engine/install/), [here](https://docs.docker.com/compose/), [here](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04) and [here](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04) for more information.

<ins>***Be warned! Please stop all VPN services before installing Docker or you might run into the installation error.***</ins>

##### Debian/Ubuntu Docker installation.

```
sudo apt update && \
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" && \
apt-cache policy docker-ce && \
sudo apt install docker-ce docker-compose-plugin -y && \
echo 'docker compose --compatibility "$@"' | sudo tee -a /usr/local/bin/docker-compose && \
sudo chmod +x /usr/local/bin/docker-compose
```

-----

### Basic usage

If your gaming PC and Linux virtual machine is on the same LAN, just run this command (You might need to be root or run with `sudo`) to start running XivMitmLatencyMitigator.

```shell
docker run -d \
  --name=xiv-mitm-latency-mitigator \
  --restart=unless-stopped \
  --net=host \
  --cap-add=NET_ADMIN \
  bankja/xivlm:latest
```

If you prefer to Docker Compose method, here is an example of **docker-compose.yml**

```yaml
version: '3'
services:
  xivlm:
    container_name: xiv-mitm-latency-mitigator
    image: bankja/xivlm:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

After created docker-compose.yml file, you need to run command `docker-compose up -d` on the same path of **docker-compose.yml** file to start running it.

Then you have to route game traffic to this virtual machine by following step 10 at <https://github.com/Soreepeong/XivMitmLatencyMitigator>

-----

### Advance usage

This container is also support running on custom VPN server if you happen to setup one. You need to add some environment variables.

| Env | Default | Example | Description |
|-----|---------|---------|-------------|
| `LOCAL` | `true` | `true` | Enable routing game traffic on LAN interface. You should set this to `false` if use on private VPN server. |
| `MITIGATOR` | `true` | `true` | `false` if you only want route game traffic. Also useful when new patch breaks the script and need to temporarily disable it or you'll not be able to login to the game. |
| `DEFINITIONS_URL` | `false` | `https://pastebin.com/raw/jf66WP69` | URL of custom definitions.json for use when official isn't update yet. Make sure that URL is link to raw text file or script will not work. Example is link to 6.38 definitions.json. |
| `LEGACY` | `false` | `false` | `true` if you want to use `iptables-legacy` instead of `iptables`. |
| `NFTABLES` | `false` | `false` | `true` if you use `nftables`. (Never tested) |
| `EXTRA_DELAY` | `0.075` | `0.035` | Manually adjust extra delay in seconds (0.075 = 75ms). If you run on a VPS, reduce this should improve respond time. |
| `MEASURE_PING` | `false` | `false` | Auto adjust extra delay. Set to `true` may worsen respond time if you use within LAN. However, when you set `VPN` to `true`, this setting will automatically set to `true` unless manually set to `false` |
| `VPN` | `false` | `false` | `true` if you are routing game traffic over VPN. |
| `VPN_INTERFACE_1` | \- | `wg0` | Name of VPN interface. You can find it with ip a command. |
| `VPN_INTERFACE_2` | \- | `zerotier` | Another VPN interface if you have. You can add many interface as you want by adding variable `VPN_INTERFACE_3` and `VPN_INTERFACE_4` and so on. |
| `VPN_INTERFACE_3` | \- | `tailscale` | Just an example. |

Example command when you using this with Wireguard on your private VPN server. Assuming that Wireguard interface name is `wg0`.

```shell
docker run -d \
  --name=xiv-mitm-latency-mitigator \
  --restart=unless-stopped \
  --net=host \
  --cap-add=NET_ADMIN \
  -e MITIGATOR=true \
  -e LOCAL=false \
  -e LEGACY=false \
  -e VPN=true \
  -e VPN_INTERFACE_1=wg0 \
  bankja/xivlm:latest
```

Here is an example of **docker-compose.yml**.

```yaml
version: '3'
services:
  xivlm:
    container_name: xiv-mitm-latency-mitigator
    image: bankja/xivlm:latest
    environment:
      - MITIGATOR=true # Default to true. Set to false when need to disable XivMitmLatencyMitigator script.
      # - DEFINITIONS_URL=https://pastebin.com/raw/jf66WP69 # URL of 6.38 definitions.json.
      - LOCAL=true # Default to true. Set to false when not use within LAN (E.g. Connect through VPN only).
      - LEGACY=false # Default to false. Set to true if you want to use iptables-legacy.
      # - NFTABLES=false # Default to false. Set to true if you use nftables.
      # - EXTRA_DELAY=0.035 # Default value is 0.075 ms.
      # - MEASURE_PING=false # Default to false. Set to true may help improve respond time on private VPN server.
      - VPN=false # Default to false. Set to true if you use this on private VPN server.
      - VPN_INTERFACE_1=wg0 # Find by using "ip a" command.
      # - VPN_INTERFACE_2=wg1
      # - VPN_INTERFACE_3=<Add many VPN interfaces as you want.>
    volumes:
      - /etc/localtime:/etc/localtime:ro
    network_mode: host
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-file: "1"
        max-size: "10m"
```

-----

### FAQ

#### Q: What to do when there is new a FFXIV patch update?

A: You will have to wait for an updated Opcodes (and sometimes [XivMitmLatencyMitigator](https://github.com/Soreepeong/XivMitmLatencyMitigator)). When the update came, just run the following command to restart container and everything will be updated automatically.

  ```
  docker restart xiv-mitm-latency-mitigator
  ```

#### Q: What will happen with my iptables rules?

A: This container will automatically created rules in 3 chains, PREROUTING, POSTROUTING and FORWARD.

* **PREROUTING** will be created by XivMitmLatencyMitigator for double weave.
* **POSTROUTING** will be created to allow routing game traffic.
* **FORWARD** will be created to allow VPN client to route game traffic.

#### Q: How to check my iptables rules?

A: Run these commands as root or with sudo to see them. However, if you use old version of Linux distro like Ubuntu 20.04, rules may not show up with these commands.

* **PREROUTING** `iptables -t nat -L PREROUTING -n -v`
* **POSTROUTING** `iptables -t nat -L POSTROUTING -n -v`
* **FORWARD** `iptables -L FORWARD -n -v`

#### Q: Will this created iptables rules stay permanent?

A: No, these newly created rules will be automatically removed when you stop (not kill) the container.

#### Q: What will happen if I kill the container instead of stopping it?

A: If you happen to kill the container, all created iptables rules will not get removed. However, if you start the container again, it will cleanup the all previously created rules before creating a new one. Then you can stop it again to remove all rules created by the container.

#### Q: How to update the container image to latest version.

A: Run following commands and it will stop, delete container and image then download the latest version.

  ```
  sudo docker stop xiv-mitm-latency-mitigator && \
  sudo docker rm xiv-mitm-latency-mitigator && \
  sudo docker image rm bankja/xivlm:latest && \
  sudo docker pull bankja/xivlm:latest
  ```

#### Q: How to permanently stop this container.

A: There are 2 methods based on how you run this container.

* If you run it with docker run command, then you can permanetly stop it by running this command.

  ```
  docker stop xiv-mitm-latency-mitigator && docker rm xiv-mitm-latency-mitigator
  ```
* If you use Docker Compose then run this command on the same path of the **docker-compose.yml** file.

  ```
  docker-compose down
  ```
