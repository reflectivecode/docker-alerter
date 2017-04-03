#!/bin/sh
set -o errexit
set -o pipefail
set -o nounset

echo "[i] create /etc/ssmtp/ssmtp.conf"
{
    echo "mailhub=${SSMTP_SERVER}";
    echo "AuthUser=${SSMTP_USER}";
    echo "AuthPass=${SSMTP_PASS}";
    echo "FromLineOverride=yes";
    echo "UseTLS=yes";
} > /etc/ssmtp/ssmtp.conf

unset SSMTP_SERVER SSMTP_USER SSMTP_PASS

while true; do
  curl --silent --show-error --unix-socket "${DOCKER_SOCKET}" -H "Accept: application/json" "http:/v1.24/events?filters=%7B%22type%22%3A%5B%22container%22%5D%7D" |
    while read line; do
        status=`echo "${line}" | jq .status -r`
        if [[ "${status:0:5}" == "exec_" ]]; then
            continue
        fi
        if [[ "${status}" == "attach" ]]; then
            continue
        fi

        name=`echo "${line}" | jq .Actor.Attributes.name -r`
        image=`echo "${line}" | jq .Actor.Attributes.image -r`
        exitCode=`echo "${line}" | jq .Actor.Attributes.exitCode -r`
        json=`echo "${line}" | jq '.'`

        if [[ "${status}" == "die" ]]; then
            logs="$(curl --silent --show-error --unix-socket /var/run/docker.sock "http:/v1.24/containers/${name}/logs?stdout=1&stderr=1&timestamps=1&since=$(($(date +%s)-60))")"
        else
            logs=""
        fi

        if [[ "${exitCode}" == "null" ]]; then
            exitCode=""
        else
            exitCode="exitcode ${exitCode}"
        fi
            ssmtp "${MAIL_TO}" << EOF
To: ${MAIL_TO}
From: ${MAIL_FROM}
Subject: ${MAIL_PREFIX}${name}

Event: ${status} ${exitCode}
Container: ${name}
Image: ${image}

${json}

${logs}
EOF
    done
done
