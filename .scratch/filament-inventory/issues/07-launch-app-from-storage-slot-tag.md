# Can a storage-slot tag open FilaManager when the app is not running?

Type: research
Status: resolved

## Question

On the current Android release target and a future iOS release, what NDEF payload and native app configuration can route a storage-slot-tag scan to the referenced storage slot when FilaManager is closed or backgrounded?

Determine the exact user interaction on each platform, including current Android NFC-dispatch restrictions, iOS notification or tap requirements, locked-device behavior, and the outcome when the app is not installed. Recommend a payload that preserves local-only inventory, supports multiple interchangeable tags for one storage slot, and never mutates inventory before in-app confirmation. Identify any domain, hosting, package, or physical-device validation requirements.

## Answer

Use one NFC Forum well-known URI record whose value is
`https://<stable-owned-domain>/s#v1.<storage-slot-id>`. Configure the URL as a
verified Android App Link now and an iOS Universal Link later. The fragment
keeps the opaque slot identifier out of HTTP requests, while the inventory and
identifier-to-slot mapping remain entirely local. Every interchangeable tag
for a storage slot contains the same URL.

On Android 16, an unlocked-phone scan routes the HTTPS record through
`ACTION_VIEW` and can cold-start or foreground FilaManager. Android 16 also
gives the user NFC-launch and supported-link controls. Android 17 shows an
explicit open-link notification before dispatch, deprecates the generic tag
intent, and adds stricter NFC-intent activity and stopped-app rules. On iPhone
XS and later, background reading shows a notification; the user must tap it,
and must unlock a locked phone, before the app receives the link. If the app is
absent, both platforms open a static web fallback.

The cross-platform path requires a stable public HTTPS domain, Android
`assetlinks.json`, iOS `apple-app-site-association`, final package/bundle and
signing identities, Flutter cold/warm deep-link handling, and real-device tests
on the Pixel 9 and future iPhone target. It requires no account, API, or cloud
inventory. Receiving a link only validates the identifier and opens a
read-only storage-slot context; all inventory changes retain their separate
explicit confirmation.

Research: [Launching FilaManager from a storage-slot tag](../research/launch-app-from-storage-slot-tag.md)
