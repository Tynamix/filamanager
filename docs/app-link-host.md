# App Link host and signing inputs

FilaManager storage-slot references use this immutable production contract:

- Host: `filamanager.vibesolutions.de`
- Route: `/s`
- Fragment: `v1.<22-character unpadded base64url storage-slot identity>`
- Android application ID: `de.vibesolutions.filamanager`
- Android signing strategy: Google Play App Signing for distributed builds

The static files in `site/` are deployed through GitHub Pages. The host contains
only Android association data and a safe browser fallback. It has no inventory
data, identifier lookup, analytics, third-party resources, or script that reads
the URL fragment.

The checked-in association file contains the current development and local
release signing fingerprint:

`0B:E1:82:51:F1:B4:4D:E3:50:86:C8:76:D3:02:A5:7B:49:9B:F7:A5:4A:B7:35:F4:DB:D0:5E:A4:D0:61:AB:6E`

Before a Play-installed build is tested, append its Play App Signing SHA-256
certificate fingerprint to the same `sha256_cert_fingerprints` array. Ticket 27
owns Play enrollment and verification of that final release fingerprint. This
does not change the physical tag payload or the Android intent filter.

The DNS owner must point `filamanager.vibesolutions.de` at the configured
GitHub Pages site and enable Pages with GitHub Actions as its source. Verify the
deployed files without redirects before provisioning physical tags:

- `https://filamanager.vibesolutions.de/.well-known/assetlinks.json`
- `https://filamanager.vibesolutions.de/s`
