# acmejson-to-secret

This package uses [traefik-acme](https://github.com/na4ma4/traefik-acme) to export TLS certificates from `acme.json` and then creates kubernetes certificates for them.

## Deploy / Configuration

```bash
curl -fSsl https://raw.githubusercontent.com/jochumdev/acmejson-to-secret/main/kube.yaml -o acmejson-to-secret.yaml
```

Edit the ENV Variables of the `CronJob`

`ACME_DOMAINS` is in the format: $domain:$namespace/$name;$domain:$namespace/$name;$domain:$namespace/$name

## License

MIT - Copyright 2024 René Jochum