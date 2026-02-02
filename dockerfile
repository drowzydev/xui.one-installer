FROM ubuntu:24.04
WORKDIR /

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install dependencies
# 2. Download/Install libssl1.1 (Required by XUI)
# 3. Create the 'xui' user that the service binary expects
RUN apt-get update && \
    apt-get install -y sudo wget unzip dos2unix python-is-python3 python3-dev mariadb-server curl libxml2 && \
    wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb || apt-get install -y -f && \
    rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    useradd -m -s /bin/bash xui && \
    apt-get clean

# Copy original xui.one files
COPY original_xui/database.sql /database.sql
COPY original_xui/xui.tar.gz /xui.tar.gz
COPY install.python3.py /install.python3.py

# Create a wrapper script
RUN echo '#!/bin/bash\n\
    service mariadb start\n\
    if [ -f "/home/xui/status" ]; then\n\
        echo "XUI already installed, starting service..."\n\
        # Ensure permissions are correct for the xui user\n\
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
