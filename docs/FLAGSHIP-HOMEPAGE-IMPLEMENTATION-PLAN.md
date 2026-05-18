# INIT HOMEPAGE — FLAGSHIP IMPLEMENTATION PLAN

## Objective
Transform the current homepage from “credible platform” into a flagship-grade cinematic infrastructure experience without modifying backend systems, Stripe validation, Azure deployment, runtime verification, or approved business copy.

---

# PHASE 1 — NAVIGATION CONSOLIDATION

## Problem
Two stacked nav systems weaken authority and create visual redundancy.

## Required
- Keep only ONE primary navigation layer.
- Preserve:
  - init identity
  - Get init CTA
  - Home / Ecosystem / Access / Pricing
- Remove the duplicated secondary nav.
- Optional:
  - replace second row with ultra-thin operational status strip.

## Outcome
The experience should immediately feel intentional and enterprise-grade.

---

# PHASE 2 — HERO BALANCE

## Problem
Hero starts too low and loses impact.

## Required
- Reduce dead vertical spacing.
- Pull hero upward closer to nav.
- Tighten typography measure.
- Increase cinematic composition balance.
- Improve whitespace rhythm.

## Preserve
- Welcome to the Venture
- Enter the Ecosystem
- Explore Architecture

## Outcome
The page should feel like:
“platform appears instantly”

Not:
“website starts below header”

---

# PHASE 3 — ECOSYSTEM VISUALIZATION

## Problem
Visualization still feels generic.

## Required
- Add:
  - telemetry paths
  - routing pulses
  - layered nodes
  - orbital movement
  - ambient operational activity
- Maintain subtlety.
- Use CSS/SVG only.
- Respect reduced-motion mode.

## Avoid
- gamer RGB
- hacker aesthetics
- military dashboard overload

## Outcome
Visualization should communicate:
“live infrastructure orchestration”

---

# PHASE 4 — METRICS + ACCESS LANES

## Metrics
- Larger numeric hierarchy
- Smaller labels
- Better separation
- Elevated glass depth
- Micro hover interactions

## Access Lanes
Group:
- Community
- Professional
- Institutional

Each lane:
- glass card
- hover lift
- subtle operational state
- icon placeholder
- stronger spacing hierarchy

---

# PHASE 5 — ATMOSPHERE SYSTEM

## Required
Add:
- layered gradients
- soft vignette
- atmospheric haze
- routing-line depth
- glow diffusion
- subtle animated lighting

## Tone
- cinematic
- restrained enterprise
- luxury infrastructure
- operational intelligence

---

# PHASE 6 — FOUNDER + FOOTER

## Founder
- intentional portrait framing
- premium founder card
- stronger quote hierarchy

## Footer
Convert footer into:
- operational trust layer
- platform metadata surface
- enterprise systems footer

Should feel:
“platform authority”
not:
“generic site footer”

---

# PHASE 7 — MOBILE VERIFICATION

## Verify
- no overflow
- hero collapse
- CTA spacing
- ecosystem scaling
- metric wrapping
- glass blur performance

## Goal
Mobile should feel:
“native operational interface”

---

# VALIDATION

dotnet build ".\src\JPVOS\JPVOS.csproj"

.\scripts\verify-runtime.ps1

.\scripts\verify-stripe-test.ps1

---

# LOCAL PREVIEW

dotnet run --project ".\src\JPVOS\JPVOS.csproj" --urls "http://localhost:5111"

Open:
http://localhost:5111

---

# NON-NEGOTIABLES

Do NOT modify:
- Stripe backend
- Discord backend
- Azure deployment
- runtime verification
- Stripe verification
- pricing/business copy
- routes
- secrets
- env files

Allowed files:
- Home.razor
- init-home.css
- App.razor only if needed for stylesheet order

