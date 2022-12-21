FROM ubuntu:22.04
WORKDIR /app

RUN apt-get update && \
    apt install curl g++ g++-multilib iptables iproute2 python-is-python3 -y && \
    rm -rf /var/lib/apt/lists/*

ADD /app/* /app/

RUN chmod +x *.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
