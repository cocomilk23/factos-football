# Mobile Web Deployment

This project is configured to export the Godot game to Web and deploy it with GitHub Pages.

## Domain

Production domain:

```text
factos.stylerewrite.xyz
```

## DNS

Create this DNS record at the DNS provider for `stylerewrite.xyz`:

```text
Type:  CNAME
Name:  factos
Value: cocomilk23.github.io
```

If the DNS provider is Cloudflare, use DNS-only mode first while GitHub Pages provisions HTTPS.

## GitHub Pages

In the GitHub repository, open `Settings -> Pages` and make sure the build source is set to `GitHub Actions`.

Set the custom domain to:

```text
factos.stylerewrite.xyz
```

The workflow in `.github/workflows/deploy-web.yml` exports the game with Godot 4.7, writes `CNAME`, and uploads the static Web build to GitHub Pages.
