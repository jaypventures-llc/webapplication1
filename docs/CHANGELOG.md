# Changelog

All notable changes to the JPV-OS Access Gateway project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Release readiness documentation (RELEASE-CHECKLIST.md)
- Changelog documentation (this file)

### Changed
- Deprecated Stripe API integration configuration (marked for future removal)
- Deprecated Discord role configuration (marked for future removal)
- Updated checkout configuration for improved clarity
- Refined pricing structure for better functionality

### Fixed
- [Describe any bug fixes]

### Removed
- [Describe any removed features]

### Deprecated
- Stripe API integration configuration (use alternative payment gateway in future releases)
- Discord role configuration (replaced with JPV-OS native role system)

### Security
- [Describe any security improvements or vulnerability fixes]

---

## [0.1.0] - 2026-05-15

### Added
- Initial JPV-OS Access Gateway release
- ASP.NET Core Blazor web application
- Role-based access control (RBAC) framework
- Dashboard shell with role-aware routing
- Governance-aligned security policy enforcement
- Container deployment support to GitHub Container Registry
- Azure App Service deployment support
- Commercial access management features
- Asset management system with asset-registry.json
- Design system with centralized CSS tokens
- PEOPLE-PROTECTION-NON-NEGOTIABLE.md governance document

### Infrastructure
- GitHub Actions CI/CD pipeline
- Docker containerization
- Automated package publishing to ghcr.io
- Development environment configuration
- Repository consolidation from WebApplication1

### Documentation
- README with operational purpose and deployment options
- CONTAINER-DEPLOYMENT.md with Docker setup
- AZURE-APP-SERVICE-DEPLOYMENT.md with cloud deployment guide
- APP-STORE-READINESS.md with app store requirements
- COMMERCIAL-ACCESS-SETUP.md with feature configuration
- COMMERCIAL-ACCESS-TESTING.md with testing procedures
- PARTNER-ASSET-REGISTER.md with asset documentation
- ASSET-REGISTRY.md with asset governance standards
- DESIGN-SYSTEM.md with design token documentation
- BRAND guidelines with naming standards

### Stack
- .NET 8.0
- Blazor (Razor Components)
- Dapper ORM (v2.1.38)
- SQLite (Microsoft.Data.Sqlite v7.0.0)
- GitHub Actions for CI/CD
- Docker for containerization

---

## Version History

The following versions represent significant milestones:

- **0.1.0** (2026-05-15): Initial release with core access gateway functionality
  - Status: Ready for commercial deployment
  - Support: jpv-os@jaypventures.llc

---

## Versioning Policy

This project follows Semantic Versioning (SEMVER):

- **MAJOR** version (X.0.0): Breaking API changes, major new features
- **MINOR** version (0.X.0): New backwards-compatible functionality
- **PATCH** version (0.0.X): Bug fixes and security updates

### Version Release Process

1. Create release branch: `release/vX.Y.Z`
2. Complete RELEASE-CHECKLIST.md verification
3. Update this CHANGELOG.md with version details
4. Merge to main with signed commit
5. Create git tag: `vX.Y.Z`
6. Deploy to production
7. Publish release notes to GitHub

---

## Support and Reporting

For bugs, feature requests, or questions about the changelog:

1. Check existing issues in the GitHub repository
2. Create a new issue with detailed information
3. For security issues, see SECURITY.md

### Contact

- **Project**: JPV-OS Access Gateway
- **Owner**: JayPVentures LLC
- **Support Email**: jpv-os@jaypventures.llc
- **Repository**: https://github.com/JayPVentures-LLC/jpv-os-access-gateway

---

## Governance Notes

All releases must comply with:

- JPV-OS governance standards and PEOPLE-PROTECTION-NON-NEGOTIABLE.md
- Role-based access control and audit requirements
- Security policy enforcement
- Asset governance standards
- Brand naming conventions and guidelines
- Accessibility and compliance requirements

Release decisions are made by the JPV-OS steering committee with approval from:

1. Release Manager
2. Technical Lead
3. Governance Officer

For more information, see RELEASE-CHECKLIST.md and governance documentation.
