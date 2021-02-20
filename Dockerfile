FROM alpine:latest

RUN apk update && apk add \
    curl \
    jq

COPY CF-DDNS-update.sh /root/CF-DDNS-update.sh  

RUN echo "*/10 * * * * /bin/sh /root/CF-DDNS-update.sh 2>&1" > /etc/crontabs/root  && \
	chmod +x /root/CF-DDNS-update.sh

CMD ["crond", "-f"]