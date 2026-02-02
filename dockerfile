FROM ubuntu:24.04
WORKDIR /

ENV DEBIAN_FRONTEND=noninteractive

# Install all libraries identified in previous steps
RUN apt-get update && \
    apt-get install -y sudo wget unzip dos2unix python-is-python3 python3-dev mariadb-server curl \
    libxml2 libxslt1.1 libmcrypt4 libmaxminddb0 libssh2-1 && \
    wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb || apt-get install -y -f && \
    rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    useradd -m -s /bin/bash xui && \
    apt-get clean

COPY original_xui/database.sql /database.sql
COPY original_xui/xui.tar.gz /xui.tar.gz
COPY install.python3.py /install.python3.py

# Enhanced wrapper script to fix Nginx paths and permissions
RUN echo '#!/bin/bash\n\
    service mariadb start\n\
    if [ -f "/home/xui/status" ]; then\n\
        echo "XUI already installed, starting service..."\n\
        mkdir -p /home/xui/logs /home/xui/bin/nginx/logs\n\
        chown -R xui:xui /home/xui\n\
        /home/xui/service start\n\
    else\n\
        echo "Starting fresh installation..."\n\
        python3 /install.python3.py\n\
    fi\n\
    tail -f /dev/null' > /wrapper.sh && \
    chmod +x /wrapper.sh

VOLUME ["/home/xui", "/var/lib/mysql"]
EXPOSE 80

ENTRYPOINT ["/wrapper.sh"]
