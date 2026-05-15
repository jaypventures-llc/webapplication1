# Asset Registry

**Last Audit:** 2026-05-15  
**Total Size:** ~45MB  
**Total Assets:** 70+ files across 16 directories

---

## Executive Summary

### Key Findings
- **Production Assets:** 52 actively used in code
- **Missing Assets:** 8 files referenced in code but not on disk (blocking issues)
- **Duplicate Assets:** 4 groups of identical files (image drift)
- **Reference Assets:** 1 (allbrands-logos.png in reference/ folder)
- **Empty Directories:** 7 (have READMEs but no content)
- **Oversized Assets:** 15 files >2MB (compression candidates)

### Critical Issues
1. **Missing directories** break code references:
   - `assets/brand/jpv-os/` (referenced by Init.razor)
   - `assets/opengraph/` (referenced by AssetPaths.cs)
   - `assets/textures/` (referenced by AssetPaths.cs)

2. **Duplicate image files** create maintenance risk and image drift:
   - Same image stored in 4+ locations (jpv-institute-hero.png, jpv-os-hero.png, jpv-os-core.png, etc.)
   - Updating one doesn't update all copies

---

## Asset Classification

### ✅ Production Assets (52 actively used)

#### Brand & Hero Images (27 files)
| Asset | Size | Location | Status | Usage |
|-------|------|----------|--------|-------|
| init-hero.png | 1.2M | init/ | ✅ | AssetPaths.Init.Hero, page hero |
| jpv-os-hero.png | 1.8M | jpv-os/ | ✅ | AssetPaths.JpvOs.Hero, landing page |
| jpv-os-brand.svg | 4.3K | jpv-os/ | ✅ | AssetPaths.JpvOs.Brand |
| jpv-os-core.png | 2.0M | jpv-os/ | ✅ | AssetPaths.JpvOs.Core, dashboard |
| jpv-os-topology.png | 2.1M | jpv-os/ | ✅ | AssetPaths.JpvOs.Topology |
| jpv-structureimage.png | 1.9M | jpv-os/ | ⚠️ | Used but not in AssetPaths |
| jaypventures-hero.png | 1.6M | jaypventures/ | ✅ | AssetPaths.JayPVentures.Hero |
| jaypventures-characterstyles1.png | 2.4M | jaypventures/ | ✅ | Marketing page |
| jaypventures-creative1.png | 2.4M | jaypventures/ | ✅ | Portfolio/gallery |
| jaypventures-creative2.png | 2.3M | jaypventures/ | ✅ | Portfolio/gallery |
| jaypventures-creative3.png | 1.8M | jaypventures/ | ✅ | Portfolio/gallery |
| jaypventures-livestream1.png | 2.3M | jaypventures/ | ✅ | Event/livestream page |
| jaypventures-livestreamagenda.png | 1.9M | jaypventures/ | ✅ | Event scheduling |
| jaypventures-stickerpack1.png | 2.4M | jaypventures/ | ✅ | Community assets |
| jaypventures-stickerpack2.png | 2.4M | jaypventures/ | ✅ | Community assets |
| jaypventures-stickerpack3.png | 2.0M | jaypventures/ | ✅ | Community assets |
| jaypventures-llc-hero.png | 1.8M | jaypventures-llc/ | ✅ | Company branding |
| jaypventures-llc-image-01.png | 1.6M | jaypventures-llc/ | ✅ | Case study/portfolio |
| jaypventures-llc-image-02.png | 2.1M | jaypventures-llc/ | ✅ | Portfolio |
| jaypventures-llc-image-03.png | 2.0M | jaypventures-llc/ | ✅ | Portfolio |
| jaypvlabs-hero.png | 2.1M | jaypVLabs/ | ✅ | AssetPaths.JayPVLabs.Hero |
| jpv-institute-hero.png | 1.9M | jpv-institute/ | ✅ | AssetPaths.JayPVLabs.InstituteHero |

#### Partner Logos (32 SVG files)
Located in `partners/` folder. All <2KB each. Includes:
- Cloud: azure.svg, cloudflare.svg, cloudflare-workers.svg, google-workspace.svg, microsoft-security.svg
- Development: github.svg, github-copilot.svg, nodejs.svg, vscode.svg, visual-studio-code.svg, powershell.svg
- Enterprise: ibm.svg, intel.svg, hashicorp.svg, unreal-editor.svg
- Social/Services: discord.svg, spotify.svg, xbox.svg, wix.svg, stripe.svg
- Education: coursera.svg, university-phoenix.svg
- Apple ecosystem: apple-icloud.svg, icloud.svg, windows.svg
- JPV Ecosystem: jpv-institute.svg, linktree.svg
- Additional: entra-id.svg, hp.svg, openai.svg, verizon.svg

**Status:** ✅ All actively used in partners section

---

### 📋 Reference Assets (1 file)
Located in `assets/reference/` (excluded from compilation per DefaultItemExcludes)

| Asset | Size | Purpose | Recommendation |
|-------|------|---------|-----------------|
| allbrands-logos.png | 1.7M | Design reference, logo compilation | ARCHIVE - move to reference bucket or docs |

---

### ❌ Missing Assets (8 files)

These files are **referenced in code** but **do not exist on disk**:

#### Critical (Causes build/runtime errors)
1. **assets/brand/jpv-os/3ab9453f-2e4e-46a5-a118-b24134dd5f65.png**
   - Referenced in: `src/JPVOS/Components/Pages/Init.razor`
   - Issue: Random UUID filename (against naming rules)
   - Recommendation: **REPLACE** - use named asset with proper naming convention
   - Action: Create or rename from existing file

2. **assets/opengraph/jpv-os-og.png**
   - Referenced in: `src/JPVOS/Services/AssetPaths.cs` (Default OG image)
   - Issue: Directory doesn't exist
   - Recommendation: **CREATE** - add OG preview image for social shares
   - Suggested size: 1200x630px

3. **assets/textures/noise.png**
   - Referenced in: `src/JPVOS/Services/AssetPaths.cs`
   - Issue: Directory doesn't exist
   - Recommendation: **CREATE** - small repeating texture pattern
   - Used for: UI overlays, background texture layers

4. **assets/textures/grid.png**
   - Referenced in: `src/JPVOS/Services/AssetPaths.cs`
   - Issue: Directory doesn't exist
   - Recommendation: **CREATE** - grid pattern texture
   - Used for: UI overlays, dashboard backgrounds

5. **assets/textures/glass.png**
   - Referenced in: `src/JPVOS/Services/AssetPaths.cs`
   - Issue: Directory doesn't exist
   - Recommendation: **CREATE** - glassmorphism texture
   - Used for: Frosted glass UI effects

#### Non-Critical (No direct code reference found, may be design remnants)
6. **assets/jaypventures/jaypventures-image-01.png**
   - Referenced in: `src/JPVOS/Services/AssetPaths.cs`
   - Status: Referenced but not used in any component
   - Recommendation: **REMOVE** from AssetPaths if truly unused

7. **assets/jaypvlabs/jaypvlabs-image-01.png**
   - Referenced in: `src/JPVOS/Services/AssetPaths.cs`
   - Status: Referenced but not used in any component
   - Recommendation: **REMOVE** from AssetPaths if truly unused

8. **assets/jpv-institute/jpv-institute-image-01.png**
   - Referenced in: `src/JPVOS/Services/AssetPaths.cs`
   - Status: Referenced but not used in any component
   - Recommendation: **REMOVE** from AssetPaths if truly unused

---

### ⚠️ Duplicate Assets (4 image collision groups)

**Problem:** Same image stored in multiple locations creates maintenance burden and image drift risk.

| Content Hash | Files (Count) | Size | Status | Recommendation |
|--------------|---------------|------|--------|-----------------|
| `55d85e165a...` | 4 files | 2.0M | DUPLICATE | Keep primary, remove 3 copies |
| `6032cbf2f2...` | 3 files | 2.1M | DUPLICATE | Keep primary, remove 2 copies |
| `daa23795...` | 2 files | 1.6M | DUPLICATE | Keep primary, remove 1 copy |
| `e2abdb664e...` | 2 files | 1.8M | DUPLICATE | Keep primary, remove 1 copy |

#### Group 1: Hash 55d85e165a...
- `jaypventures-llc/jaypventures-llc-image-03.png` (2.0M)
- `jaypVLabs/jpv-institute-hero.png` (1.9M)
- `jpv-institute/jpv-institute-hero.png` (2.0M)
- `jpv-os/jpv-os-core.png` (2.0M)

**Issue:** Same image, 4 different locations. Inconsistent naming and structure.  
**Recommendation:** 
- Keep single canonical: `jpv-institute/jpv-institute-hero.png`
- Remove duplicates from jpv-os/, jaypVLabs/, jaypventures-llc/
- Update AssetPaths.cs to reference canonical location
- Or: Use as jpv-os-core.png but only store once

#### Group 2: Hash 6032cbf2f2...
- `jaypVLabs/jaypvlabs-hero.png` (2.1M)
- `jaypventures-llc/jaypventures-llc-image-02.png` (2.1M)
- `jpv-os/jpv-os-topology.png` (2.1M)

**Issue:** Appears to be topology/structure diagram used across multiple brands.  
**Recommendation:**
- Keep single: `jpv-os/jpv-os-topology.png`
- Remove from jaypVLabs/ and jaypventures-llc/
- Or: Move to `illustrations/` if it's a shared diagram

#### Group 3: Hash daa23795...
- `jaypventures-llc/jaypventures-llc-image-01.png` (1.6M)
- `jaypventures/jaypventures-hero.png` (1.6M)

**Issue:** Same hero image used for both JayPVentures and JayPVentures LLC.  
**Recommendation:**
- Keep: `jaypventures/jaypventures-hero.png`
- Remove: `jaypventures-llc/jaypventures-llc-image-01.png`

#### Group 4: Hash e2abdb664e...
- `jaypventures-llc/jaypventures-llc-hero.png` (1.8M)
- `jpv-os/jpv-os-hero.png` (1.8M)

**Issue:** Same hero image used for JayPVentures LLC and JPV-OS.  
**Recommendation:**
- Keep: `jpv-os/jpv-os-hero.png` (matches folder)
- Remove: `jaypventures-llc/jaypventures-llc-hero.png`
- Or: Both are legitimate distinct uses; verify design intent

---

### 📦 Oversized Assets (15 files >2MB)

These are candidates for compression or webp conversion:

| Asset | Size | Folder | Type | Recommendation |
|-------|------|--------|------|-----------------|
| jaypventures-characterstyles1.png | 2.4M | jaypventures/ | Illustration | COMPRESS or convert to WebP |
| jaypventures-creative1.png | 2.4M | jaypventures/ | Portfolio | COMPRESS or convert to WebP |
| jaypventures-stickerpack1.png | 2.4M | jaypventures/ | Sticker pack | COMPRESS or convert to WebP |
| jaypventures-stickerpack2.png | 2.4M | jaypventures/ | Sticker pack | COMPRESS or convert to WebP |
| jaypventures-creative2.png | 2.3M | jaypventures/ | Portfolio | COMPRESS or convert to WebP |
| jaypventures-livestream1.png | 2.3M | jaypventures/ | Event marketing | COMPRESS or convert to WebP |
| jaypventures-llc-image-02.png | 2.1M | jaypventures-llc/ | Portfolio | COMPRESS or convert to WebP |
| jaypventures-llc-image-03.png | 2.0M | jaypventures-llc/ | Portfolio | COMPRESS or convert to WebP |
| jaypVLabs/jaypvlabs-hero.png | 2.1M | jaypVLabs/ | Hero | COMPRESS or convert to WebP |
| jpv-os/jpv-os-topology.png | 2.1M | jpv-os/ | Diagram | COMPRESS or convert to WebP |
| jpv-os/jpv-os-core.png | 2.0M | jpv-os/ | System diagram | COMPRESS or convert to WebP |

**Total oversized:** 26.5MB (59% of total assets)

**Recommended action:** Convert PNG to WebP format (typically 30-50% size reduction) and serve with PNG fallback for older browsers.

---

### 📁 Empty Directories (7 folders)

These directories have READMEs describing their purpose but contain no actual assets:

1. **backgrounds/** - "Full-page background images and abstract environment assets"
2. **hero/** - "Primary landing visuals and above-the-fold compositions"
3. **illustrations/** - "Non-logo diagrams, concepts, scenes, and visual explainers"
4. **logos/** - "Logo collections and brand marks"
5. **motion/** - "Lottie, JSON, MP4, WEBM, or animation-ready assets"
6. **typography/** - "Type lockups, text treatments, and wordmark-safe exports"
7. **ui/glass/** - "Glassmorphism panels, frosted cards, light refraction layers"
8. **ui/gradients/** - "Approved gradient backgrounds and accent bands"
9. **ui/icons/** - "System UI icons only; brand logos stay in brand folders"
10. **ui/overlays/** - "Noise, grid, glow, vignette, and depth overlays"
11. **ui/surfaces/** - "Reusable panels, cards, shells, and interface surfaces"

**Recommendation:** 
- Keep structure as defined in asset-registry.json (governance)
- These are placeholders for organized future growth
- Fill as needed or remove if scope won't support them

---

## Governance Rules

From `asset-registry.json` standard:

### ✅ Protected Rules
1. ✅ Do not store private compliance screenshots in public wwwroot assets
2. ✅ Do not use random generated filenames in production
3. ✅ Do not place brand logos inside ui folders
4. ✅ Do not overwrite existing approved logo files

### Naming Conventions
- Format: `lowercase-kebab-case`
- Examples: `glass-command-panel.webp`, `gradient-enterprise-blue.svg`, `icon-routing.svg`
- **Violations found:** `3ab9453f-2e4e-46a5-a118-b24134dd5f65.png` (random UUID)

### Folder Structure
Per asset-registry.json standard:
```
assets/
├── hero/                    # Primary landing visuals
├── ui/
│   ├── icons/             # System UI icons
│   ├── surfaces/          # Reusable panels, cards
│   ├── overlays/          # Noise, grid, glow, vignette
│   ├── gradients/         # Approved gradient backgrounds
│   └── glass/             # Glassmorphism panels
├── backgrounds/           # Full-page background images
├── illustrations/         # Diagrams, concepts, scenes
├── motion/               # Lottie, JSON, MP4, WEBM
├── typography/           # Type lockups, wordmarks
├── partners/             # Partner/integration logos
├── [brand-folders]/      # Brand-specific assets (jpv-os, jaypventures, etc.)
└── reference/            # Reference assets (excluded from production)
```

---

## Detailed Asset Directory Breakdown

### jpv-os/ (5 files, 7.7M)
**Status:** ✅ Active production folder  
**Files:**
- jpv-os-hero.png (1.8M) - Landing page hero
- jpv-os-brand.svg (4.3K) - Brand mark
- jpv-os-core.png (2.0M) - System diagram [DUPLICATE GROUP 1]
- jpv-os-topology.png (2.1M) - Structure diagram [DUPLICATE GROUP 2] [OVERSIZED]
- jpv-structureimage.png (1.9M) - Organization chart
**Recommendation:** Core production assets, keep all but deduplicate

### jaypventures/ (10 files, 22M)
**Status:** ✅ Active production folder  
**Files:**
- jaypventures-hero.png (1.6M) - Primary hero [DUPLICATE GROUP 3]
- jaypventures-characterstyles1.png (2.4M) - Character styles [OVERSIZED]
- jaypventures-creative1.png (2.4M) - Portfolio [OVERSIZED]
- jaypventures-creative2.png (2.3M) - Portfolio [OVERSIZED]
- jaypventures-creative3.png (1.8M) - Portfolio
- jaypventures-livestream1.png (2.3M) - Event marketing [OVERSIZED]
- jaypventures-livestreamagenda.png (1.9M) - Event schedule
- jaypventures-stickerpack1.png (2.4M) - Community asset [OVERSIZED]
- jaypventures-stickerpack2.png (2.4M) - Community asset [OVERSIZED]
- jaypventures-stickerpack3.png (2.0M) - Community asset
- README.md (300 bytes)
**Recommendation:** Core production, compress oversized files, remove missing Image01

### jaypventures-llc/ (4 files, 7.4M)
**Status:** ✅ Active production folder  
**Files:**
- jaypventures-llc-hero.png (1.8M) [DUPLICATE GROUP 4]
- jaypventures-llc-image-01.png (1.6M) [DUPLICATE GROUP 3]
- jaypventures-llc-image-02.png (2.1M) [DUPLICATE GROUP 2] [OVERSIZED]
- jaypventures-llc-image-03.png (2.0M) [DUPLICATE GROUP 1]
**Recommendation:** Deduplicate, keep unique hero for brand identity

### jaypVLabs/ (3 files, 4M)
**Status:** ⚠️ Mixed production/duplicate  
**Files:**
- jaypvlabs-hero.png (2.1M) [DUPLICATE GROUP 2] [OVERSIZED]
- jpv-institute-hero.png (1.9M) [DUPLICATE GROUP 1]
- README.md (297 bytes)
**Note:** Naming inconsistency (jaypVLabs vs jaypventures-llc vs jpv-institute)
**Recommendation:** Rename folder for consistency, deduplicate, move institute hero to jpv-institute/

### jpv-institute/ (1 file, 2M)
**Status:** ✅ Core production  
**Files:**
- jpv-institute-hero.png (2.0M)
**Recommendation:** Keep, use as canonical jpv-institute-hero.png

### init/ (1 file, 1.2M)
**Status:** ✅ Core production  
**Files:**
- init-hero.png (1.2M) - Init flow hero
**Recommendation:** Keep, referenced in AssetPaths

### partners/ (32 files, 128K)
**Status:** ✅ Active, well-managed  
**Files:** All SVG partner logos, <2KB each  
**Recommendation:** Excellent compression; keep all

### reference/ (1 file, 1.7M)
**Status:** 📋 Reference/archive  
**Files:**
- allbrands-logos.png (1.7M) - Design reference compilation
**Note:** Correctly placed in reference/ folder (excluded from build)
**Recommendation:** Keep for design reference or move to docs/

### Empty/Placeholder Directories (7 folders)
- backgrounds/, hero/, illustrations/, logos/, motion/, typography/
- ui/glass/, ui/gradients/, ui/icons/, ui/overlays/, ui/surfaces/

**Recommendation:** Keep structure, fill as brand grows

---

## Action Items

### 🚨 Critical (Blocks functionality)
- [ ] Create missing `assets/brand/jpv-os/` directory with proper asset (remove UUID filename)
- [ ] Create missing `assets/opengraph/` directory with jpv-os-og.png
- [ ] Create missing `assets/textures/` directory with noise.png, grid.png, glass.png

### ⚠️ High Priority (Prevents image drift)
- [ ] Deduplicate Group 1 images (4 copies of same image)
- [ ] Deduplicate Group 2 images (3 copies of same image)
- [ ] Deduplicate Group 3 images (2 copies of same image)
- [ ] Deduplicate Group 4 images (2 copies of same image)
- [ ] Update AssetPaths.cs to reference canonical locations

### 📦 Medium Priority (Optimize delivery)
- [ ] Convert oversized PNGs to WebP (15 files >2MB)
- [ ] Compress remaining PNGs (target <1.5MB for photos, <500KB for illustrations)

### 📋 Low Priority (Cleanup)
- [ ] Remove unused Image01 references from AssetPaths.cs if confirmed unused
- [ ] Move reference/allbrands-logos.png to docs/ or archive bucket if not needed
- [ ] Rename jaypVLabs folder to jaypv-labs for consistency

---

## Validation Checklist

- [x] Asset inventory complete
- [x] Duplicates identified and documented
- [x] Missing assets identified
- [x] Oversized assets identified
- [x] Governance rules documented
- [x] Folder structure against asset-registry.json verified
- [ ] Missing assets created/replaced
- [ ] Duplicates removed (post-documentation)
- [ ] PNGs converted to WebP (post-documentation)
- [ ] Build validation: `dotnet build`

---

## References

- **Asset Registry Standard:** `src/JPVOS/wwwroot/assets/asset-registry.json`
- **Asset Manifest:** `src/JPVOS/wwwroot/assets/asset-manifest.json`
- **Asset Paths Code:** `src/JPVOS/Services/AssetPaths.cs`
- **Build Configuration:** `src/JPVOS/JPVOS.csproj` (DefaultItemExcludes)
