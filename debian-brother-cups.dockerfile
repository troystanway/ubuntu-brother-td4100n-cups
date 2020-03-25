FROM amd64/debian:latest

# Install Packages (basic tools, cups, basic drivers, HP drivers)
RUN apt-get update \
&& apt-get install -y \
  sudo \
  whois \
  cups \
  curl \
  nano \
  cups-client \
  cups-bsd \
  cups-filters \
  lib32stdc++6 \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
# Add user and disable sudo password checking
RUN useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/print \
  --shell=/bin/bash \
  --password=$(mkpasswd print) \
  print \
&& sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

RUN mkdir -p /var/spool/lpd/td4100n

RUN curl https://download.brother.com/welcome/dlfp100139/td4100nlpr-1.0.3-0.i386.deb --output td4100nlpr-1.0.3-0.i386.deb && \
    dpkg -i --force-all td4100nlpr-1.0.3-0.i386.deb && \
    curl https://download.brother.com/welcome/dlfp100140/td4100ncupswrapper-1.0.3-0.i386.deb --output td4100ncupswrapper-1.0.3-0.i386.deb && \
    dpkg -i --force-all td4100ncupswrapper-1.0.3-0.i386.deb && \
    dpkg -l | grep Brother && \
    rm -f td4100nlpr-1.0.3-0.i386.deb td4100ncupswrapper-1.0.3-0.i386.deb && \
    apt-get purge -y curl libcurl4 libnghttp2-14 libpsl5 librtmp1 publicsuffix

RUN sed -i 's/Listen localhost:631/Port 632/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

# Configure the service's to be reachable
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid)


# Default shell
CMD ["/usr/sbin/cupsd", "-f"]