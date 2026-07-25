# Reference Image Guidelines

Rules and conventions for the `reference-images/` library used by the Banana Squad pipeline.

## File Naming Convention

```
{descriptor}[-{detail}]-{NN}.{ext}
```

- **Lowercase**, **hyphen-separated**, **zero-padded** two-digit sequence number
- No spaces, underscores, or special characters
- Keep descriptors short but meaningful

### Examples by Category

| Category | Example filenames |
|---|---|
| `style/` | `watercolor-warm-01.png`, `flat-vector-01.png`, `photorealistic-studio-01.jpg` |
| `composition/` | `rule-of-thirds-01.jpg`, `centered-symmetrical-01.png`, `hero-banner-16x9-01.jpg` |
| `subject/` | `product-bottle-01.jpg`, `headshot-professional-01.jpg`, `diagram-flowchart-01.png` |
| `brand/` | `logo-primary-01.png`, `palette-core-01.png`, `typography-sample-01.png` |
| `output-examples/` | `social-post-goal-01.png`, `mockup-goal-01.png`, `diagram-goal-01.png` |

## Categories

| Category | Purpose | Min images |
|---|---|---|
| `style/` | Aesthetic references (watercolor, flat, photorealistic, etc.) | 5 |
| `composition/` | Layout and spatial arrangement patterns | 4 |
| `subject/` | Core products, people, or objects you generate around | 3 |
| `brand/` | Logos, color palettes, typography samples | 3 |
| `output-examples/` | "Gold standard" target outputs for the Critic agent | 5 |

**Total minimum: 20 images** for a functional reference library.

## Format & Resolution

| Rule | Details |
|---|---|
| Accepted formats | PNG, JPG, JPEG, WebP |
| Minimum resolution | 1024px on shortest side |
| Preferred format | PNG for graphics/logos/diagrams; JPG/WebP for photos |
| Max file size | 20MB per image (API upload limit) |
| Transparency | Use PNG when transparency matters (logos, icons, overlays) |

The Gemini 3 Pro Image API accepts up to **14 reference images** per request and outputs up to 4K. Reference images should be at least 1K so the model receives sharp input.

## Screenshots as References

Screenshots are acceptable reference images. When using them:

- Crop to the relevant portion only (remove browser chrome, OS UI)
- Ensure the cropped image is still at least 1024px wide
- Save as PNG to avoid JPEG compression artifacts on text/UI elements

## Manifest

All images must be cataloged in [`manifest.yaml`](manifest.yaml) at the root of `reference-images/`. Update the manifest whenever images are added or removed. Each entry includes:

- `file` -- filename (must match the file on disk exactly)
- `description` -- one-line plain-English description of what the image shows
- `use_case` -- list of applicable contexts: `marketing`, `social`, `mockup`, `ecommerce`, `diagram`, `editorial`, `all`
- `tags` -- freeform list for searchability

## How the Pipeline Uses References

1. **Research Agent** reads the manifest and analyzes images matching the user's request
2. **Prompt Architect** grounds narrative prompts in the analyzed reference images
3. **Generator Agent** passes selected references to the Gemini API `contents` array
4. **Critic Agent** compares outputs against `output-examples/` gold standards

The Research Agent will browse the entire library when no specific reference is provided, so well-organized filenames and manifest entries directly improve generation quality.

## What to Collect First

Priority order for populating an empty library:

1. **Brand assets** -- logo, palette, typography (you likely have these already)
2. **Subject photos** -- your core products or subjects
3. **Output examples** -- find or create 5 images representing your target quality, one per variant type (Faithful, Enhanced, Alt Composition, Style Variation, Bold/Creative)
4. **Style references** -- save examples from Dribbble, Behance, or existing materials that match desired aesthetics
5. **Composition references** -- grab layouts you like from social posts, product pages, or design templates; focus on spatial arrangement, not content
