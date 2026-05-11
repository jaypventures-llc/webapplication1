# JPV-OS App Store Readiness Checklist

## Current App Status

Current project type: ASP.NET Core web application.

This project can be published as a hosted web app. It cannot be submitted directly to Apple App Store, Google Play, or Microsoft Store without a native or hybrid app shell.

## Required Store Architecture

- Web/backend: ASP.NET Core web app
- Shared UI/components: Razor Class Library where applicable
- Store shell: .NET MAUI Blazor Hybrid or Windows app shell
- Authentication: production identity provider
- Entitlements: JPV-OS entitlement and audit boundary
- Privacy: public privacy policy URL
- Terms: public terms of service URL
- Support: public support URL and contact mailbox

## Microsoft Store

- [ ] Create MSIX-capable Windows app shell
- [ ] Reserve app name in Partner Center
- [ ] Configure package identity
- [ ] Configure signing certificate
- [ ] Add app icon and screenshots
- [ ] Complete age rating
- [ ] Add privacy policy URL
- [ ] Build release package
- [ ] Submit for certification

## Google Play

- [ ] Create Android-capable .NET MAUI app
- [ ] Configure application ID
- [ ] Configure release keystore
- [ ] Build signed AAB
- [ ] Create Play Console listing
- [ ] Complete Data Safety form
- [ ] Add privacy policy URL
- [ ] Add screenshots and app icon
- [ ] Internal test release
- [ ] Production submission

## Apple App Store

- [ ] Enroll in Apple Developer Program
- [ ] Configure bundle identifier
- [ ] Configure certificates and provisioning profiles
- [ ] Build iOS release through Mac build host
- [ ] Create App Store Connect record
- [ ] Complete privacy nutrition labels
- [ ] Add screenshots and app icon
- [ ] TestFlight review
- [ ] Production submission

## JPV-OS Governance Requirements

- [ ] 18+ default access posture documented
- [ ] No child-directed monetization
- [ ] No behavioral advertising without explicit lawful basis
- [ ] No unlawful surveillance or coercive profiling
- [ ] User data minimization documented
- [ ] Audit logging boundaries documented
- [ ] Public support and appeal path documented
- [ ] Security contact documented
- [ ] Store descriptions reviewed for accuracy
- [ ] Claims reviewed against evidence standard

## Release Gate

No store submission is approved until privacy, terms, support, signing, screenshots, security, entitlement, and governance checks are complete.
