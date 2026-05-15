# JPV-OS Public Assets

**Centralized asset library for JPV-OS Access Gateway**

This folder contains all public-facing image, icon, and media assets used in the JPV-OS platform. Assets are organized by category and purpose to maintain visual consistency and prevent image drift.

---

## Organization Structure

```
assets/
├── jpv-os/                  # JPV-OS platform visuals & brand
│   ├── jpv-os-hero.png           # Landing page hero
│   ├── jpv-os-brand.svg          # Brand mark/logo
│   ├── jpv-os-core.png           # System core diagram
│   ├── jpv-os-topology.png       # Architecture topology
│   └── jpv-structureimage.png    # Organization structure
├── jaypventures/            # JayPVentures brand assets
│   ├── jaypventures-hero.png     # Primary hero image
│   ├── jaypventures-creative*.png  # Portfolio creative pieces
│   ├── jaypventures-characterstyles*.png  # Character design
│   ├── jaypventures-livestream*.png  # Event/livestream content
│   ├── jaypventures-stickerpack*.png  # Community stickers
│   └── README.md
├── jaypventures-llc/        # JayPVentures LLC company visuals
│   ├── jaypventures-llc-hero.png # Company hero
│   ├── jaypventures-llc-image-*.png  # Case studies & portfolio
│   └── README.md
├── jaypVLabs/               # JayPVLabs initiative assets
│   ├── jaypvlabs-hero.png   # Initiative hero
│   ├── jpv-institute-hero.png # JPV Institute hero
│   └── README.md
├── jpv-institute/           # JPV Institute branding
│   ├── jpv-institute-hero.png # Institute hero
│   └── README.md
├── init/                    # init flow assets
│   ├── init-hero.png        # Onboarding hero
│   └── README.md
├── partners/                # Third-party integration logos
│   ├── github.svg           # GitHub
│   ├── cloudflare.svg       # Cloudflare
│   ├── microsoft.svg        # Microsoft
│   ├── stripe.svg           # Stripe
│   └── [32 total partner logos]
│   └── README.md
├── hero/                    # [Empty] Future primary landing visuals
│   └── README.md
├── backgrounds/             # [Empty] Future full-page backgrounds
│   └── README.md
├── illustrations/           # [Empty] Future diagrams & explainers
│   └── README.md
├── logos/                   # [Empty] Future logo collections
│   └── README.md
├── motion/                  # [Empty] Future animations (Lottie, MP4, WEBM)
│   └── README.md
├── typography/              # [Empty] Future type lockups & wordmarks
│   └── README.md
├── ui/                      # UI component assets
│   ├── glass/               # [Empty] Glassmorphism panels & frosted cards
│   ├── gradients/           # [Empty] Approved gradient backgrounds
│   ├── icons/               # [Empty] System UI icons
│   ├── overlays/            # [Empty] Noise, grid, glow, vignette effects
│   ├── surfaces/            # [Empty] Reusable panels, cards, shells
│   └── README.md
├── reference/               # [Excluded from build] Design references
│   ├── allbrands-logos.png  # Logo compilation reference
│   └── README.md
├── asset-registry.json      # [Manifest] Asset folder standards & governance
├── asset-manifest.json      # [Manifest] Generated asset inventory
└── README.md                # [This file] Asset governance & guidelines
```

---

## Asset Categories

### 🎨 Brand & Platform Assets

**JPV-OS Core**
- Folder: `jpv-os/`
- Purpose: Platform identity, architecture, and system visuals
- Content: Hero, brand mark, system diagrams, topology charts
- Status: ✅ Production

**JayPVentures**
- Folder: `jaypventures/`
- Purpose: Brand portfolio, creative work, event content
- Content: Hero, creative pieces, character design, sticker packs, livestream content
- Status: ✅ Production

**JayPVentures LLC**
- Folder: `jaypventures-llc/`
- Purpose: Company branding and case studies
- Content: Hero, portfolio images, company visuals
- Status: ✅ Production

**JayPVLabs & JPV Institute**
- Folders: `jaypVLabs/`, `jpv-institute/`
- Purpose: Initiative and educational branding
- Content: Initiative heroes, institute branding
- Status: ✅ Production

**init Flow**
- Folder: `init/`
- Purpose: Onboarding/initialization flow visuals
- Content: Hero image for init experience
- Status: ✅ Production

### 🔗 Partner Integration Assets

**partners/**
- Purpose: Third-party platform logos (GitHub, Cloudflare, Stripe, etc.)
- Content: 32 SVG logos (all <2KB)
- Format: SVG (preferred for logos)
- Status: ✅ Production

### 📁 Reserved Folders (Future Use)

The following folders are reserved for future asset growth but currently empty:
- `hero/` - Primary landing page visuals
- `backgrounds/` - Full-page background images
- `illustrations/` - Diagrams and visual explainers
- `logos/` - Logo collections
- `motion/` - Animations (Lottie, MP4, WEBM)
- `typography/` - Type lockups and wordmark treatments
- `ui/icons/` - System UI icons
- `ui/surfaces/` - Reusable UI panels and cards
- `ui/overlays/` - Effect overlays (noise, grid, glow)
- `ui/gradients/` - Approved gradient backgrounds
- `ui/glass/` - Glassmorphism textures

### 📋 Reference Assets

**reference/**
- Purpose: Design reference materials (excluded from production build)
- Content: allbrands-logos.png (1.7M compilation image)
- Visibility: Not served in production
- Build: Excluded via `DefaultItemExcludes` in JPVOS.csproj

---

## Governance Rules

### ✅ Required Standards

1. **Naming Convention**: Use `lowercase-kebab-case` for all filenames
   - ✅ Good: `glass-command-panel.webp`, `gradient-enterprise-blue.svg`
   - ❌ Bad: `3ab9453f-2e4e-46a5-a118-b24134dd5f65.png`, `Image01.png`

2. **No Random Filenames**: Never use UUIDs, timestamps, or generated names in production
   - ✅ Good: `jpv-os-hero.png`
   - ❌ Bad: `image-3ab9453f.png`, `asset_12345.png`

3. **Public Assets Only**: Do not store private content in wwwroot
   - ❌ Don't store: Compliance screenshots, internal diagrams, employee photos, confidential mockups
   - ✅ Store: Public brand assets, marketing visuals, partner logos

4. **Brand Organization**: Brand logos must stay in brand folders, not in `ui/` folders
   - ✅ Good: Assets in `jpv-os/`, `jaypventures/`, `partners/`
   - ❌ Bad: Brand logos in `ui/icons/`

5. **No Overwrites**: Once an asset is approved and used, keep the original file
   - Never replace approved assets with new versions unless intentional refactoring
   - If updating: Create version, get approval, then replace atomically
   - Document breaking changes in ASSET-REGISTRY.md

6. **Canonical Locations**: Each asset lives in exactly one location
   - Use symlinks or code references if duplication seems necessary
   - Document all cross-references in AssetPaths.cs

### 📏 Size Guidelines

**Target sizes (compressed, before serving):**
- Hero images: 1-2MB (high quality, full-page visuals)
- Portfolio/gallery: 1.5-2MB (rich content, acceptable for slower connections)
- Icons/logos: <100KB (SVG preferred, raster <50KB)
- Textures/overlays: <500KB (repeating patterns, UI elements)
- Social preview (OG): <300KB (square or 1.2:1 aspect ratio)

**Oversized assets** (>2MB) are compression candidates:
- Prefer WebP format (30-50% smaller than PNG)
- Provide PNG fallback for older browsers
- Consider image optimization tools (tinypng, imageoptim)

### 🔒 Access Control

**Excluded from build (reference/):**
- Located in `assets/reference/` folder
- Marked in JPVOS.csproj with `DefaultItemExcludes`
- Not served in production
- Used for design research only

---

## Using Assets in Code

### C# (Razor Components, Pages)

Assets are referenced via the centralized `AssetPaths` class:

```csharp
// From: src/JPVOS/Services/AssetPaths.cs
using JPVOS.Services;

<img src="@AssetPaths.JpvOs.Hero" alt="JPV-OS hero" />
<img src="@AssetPaths.JayPVentures.Hero" alt="JayPVentures hero" />
<img src="@AssetPaths.Partners.Github" alt="GitHub" />
```

**Benefits:**
- Single source of truth for asset paths
- Type-safe references (no string typos)
- Easy refactoring (change path once, updates everywhere)
- Automatic asset validation in code review

### HTML

For static HTML, use direct paths with `/assets/` prefix:

```html
<img src="/assets/jpv-os/jpv-os-hero.png" alt="JPV-OS" />
<img src="/assets/partners/github.svg" alt="GitHub" />
```

---

## Adding New Assets

### Step 1: Determine Category
- Brand visual? → Brand folder (e.g., `jaypventures/`)
- Partner logo? → `partners/`
- UI component? → `ui/[category]/`
- Design reference? → `reference/`

### Step 2: Name Properly
- Use `lowercase-kebab-case`
- Be descriptive: `jpv-os-topology.png` not `diagram.png`
- Include purpose: `glass-command-panel.webp` not `panel.webp`
- No UUIDs or timestamps

### Step 3: Optimize
- PNG/JPG → Consider WebP conversion (target <2MB for photos)
- SVG → Prefer for logos and icons (already optimized)
- Verify size with `ls -lh`

### Step 4: Update Code Reference
If asset should be public API:
- Add constant to `src/JPVOS/Services/AssetPaths.cs`
- Document in README.md folder (if new directory)
- Reference via `AssetPaths.*` in components

### Step 5: Verify
- Run `dotnet build` to ensure no conflicts
- Load page in browser to confirm image renders
- Check browser network tab for file size
- Add entry to `docs/ASSET-REGISTRY.md`

---

## Preventing Image Drift

**Image drift:** When the same visual is stored in multiple locations and updates don't sync.

### Prevention Strategies

1. **Single Canonical Location**
   - Store each unique image exactly once
   - Reference from code (AssetPaths.cs)
   - Never duplicate in filesystem

2. **Regular Audits** (this document is version 1)
   - Run `find assets -type f -exec md5sum {} \; | sort` to find duplicates
   - Check for unused referenced assets in AssetPaths.cs
   - Update `docs/ASSET-REGISTRY.md` quarterly

3. **Naming Discipline**
   - Consistent naming prevents accidental confusion
   - Brand-specific folders prevent collisions
   - Code references prevent typos

4. **Version Control**
   - Commit changes to git with meaningful messages
   - Review asset changes in PRs (visually if possible)
   - Track when assets are added/removed

---

## Manifest Files

### asset-registry.json
Machine-readable standard for asset folder structure, naming conventions, and protected rules.
- Auto-generated or manually maintained
- Reference for tooling and validation
- Current standard: "JPV-OS public asset structure"

### asset-manifest.json
Inventory of production-ready assets with metadata:
- Asset name, relative path, file extension
- File size in KB
- Public visibility flag
- Last generated: See file header

**Use asset-manifest.json for:**
- Build-time asset validation
- Performance audits (size tracking)
- Public API documentation
- Cache busting strategies

---

## Troubleshooting

### Missing Asset Errors
**Problem:** Component renders broken image or 404
1. Check spelling in `AssetPaths.cs` constant name
2. Verify file exists at referenced path: `ls -la src/JPVOS/wwwroot/assets/path/to/file`
3. Verify path separators are correct: `/` not `\`
4. Run `dotnet build` to catch path issues

### Image Drift
**Problem:** Same image looks different in different places
1. Get MD5 hash: `md5sum file1 file2`
2. If hashes don't match: Different images, update one
3. If hashes match: Duplicate files! Remove duplicates, update code references

### Asset Size Issues
**Problem:** Page loads slowly, images oversized
1. Check size: `ls -lh assets/path/file.png`
2. Compress: `imageoptim file.png` or convert to WebP
3. Use `<picture>` element for format fallback:
   ```html
   <picture>
     <source srcset="image.webp" type="image/webp">
     <img src="image.png" alt="Description">
   </picture>
   ```

### Build Excludes
**Problem:** Assets in `reference/` should not be deployed
- Configured in `src/JPVOS/JPVOS.csproj` via `DefaultItemExcludes`
- Reference folder is automatically excluded
- Verify with `dotnet publish` (reference assets won't be in output)

---

## Related Documentation

- **Full Asset Inventory:** `docs/ASSET-REGISTRY.md`
- **Asset Paths Code:** `src/JPVOS/Services/AssetPaths.cs`
- **Asset Manifest:** `asset-manifest.json` (current inventory)
- **Asset Registry Standard:** `asset-registry.json` (structure & rules)
- **Build Config:** `src/JPVOS/JPVOS.csproj` (exclude rules)
- **Design System:** `docs/DESIGN-SYSTEM.md` (visual standards)

---

## Changelog

### 2026-05-15 (v1.0)
- Initial asset audit completed
- Identified 8 missing assets (critical blocking issues)
- Identified 4 duplicate image groups
- Identified 15 oversized assets (>2MB)
- Created ASSET-REGISTRY.md with detailed inventory
- Created this governance README.md
- Recommendations: deduplicate, create missing assets, compress oversized PNGs to WebP

---

**Last Updated:** 2026-05-15  
**Maintainer:** JPV-OS Team  
**Review Cycle:** Quarterly or on major version releases
