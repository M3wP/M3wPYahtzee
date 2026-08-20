# Builds and runs the M3wP Yahtzee! CLI server.
#
#   docker build -t m3wp-yahtzee-server .
#   docker run -d --restart unless-stopped -p 7632:7632 --name yahtzee m3wp-yahtzee-server
#
# -d detaches so it keeps running after you close the SSH session;
# --restart unless-stopped brings it back after a crash or host reboot
# too. Same effect either way with docker-compose.yml: docker compose
# up -d.
#
# Extra server args (-m <max conns>, -s silent, -d debug log) can be
# appended after the image name, e.g.:
#   docker run -d --restart unless-stopped -p 7632:7632 --name yahtzee m3wp-yahtzee-server -m 50
#
# Management once it's running detached:
#   docker logs -f yahtzee      follow server output
#   docker stop yahtzee         stop it (won't auto-restart after this)
#   docker restart yahtzee      restart it

FROM debian:bookworm-slim AS build

RUN apt-get update && \
    apt-get install -y --no-install-recommends fpc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Only what the server target actually needs (see M3wPYahtzeeCLIServer.lpi) -
# not the GUI client, MEGA65 client, or anything under FMX/backup/M65.
COPY M3wPYahtzeeCLIServer.lpr YahtzeeClasses.pas YahtzeeServer.pas TCPServer.pas ./
COPY synalist-code ./synalist-code

RUN mkdir /out && \
    fpc -Mdelphi -O2 -Fusynalist-code -FE/out M3wPYahtzeeCLIServer.lpr


FROM debian:bookworm-slim

RUN useradd --system --no-create-home --shell /usr/sbin/nologin yahtzee

WORKDIR /app
COPY --from=build /out/M3wPYahtzeeCLIServer ./
COPY motd ./motd

USER yahtzee

# Game port (see TCPListener:= TTCPListener.Create('7632') in
# M3wPYahtzeeCLIServer.lpr)
EXPOSE 7632/tcp

ENTRYPOINT ["./M3wPYahtzeeCLIServer"]
