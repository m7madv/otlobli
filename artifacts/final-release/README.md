# Final release artifacts

Signed artifacts are intentionally not committed. After the required GitHub
secrets are configured, manually run `.github/workflows/final-release-candidate.yml`.
The workflow writes signed iOS and Android files plus SHA-256 manifests under
this directory and uploads them as private GitHub Actions artifacts. It never
submits to App Store Connect or Google Play.
