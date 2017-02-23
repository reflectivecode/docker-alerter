# docker-alerter
Send email alerts for docker events

## Use

```
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e "SSMTP_SERVER=email-smtp.us-east-1.amazonaws.com:465" \
  -e "SSMTP_USER=SMTP_USERNAME" \
  -e "SSMTP_PASS=SMTP_PASSWORD" \
  -e "MAIL_TO=user@example.com" \
  -e "MAIL_FROM=John Doe <user@example.com>" \
  reflectivecode/docker-alerter
```
