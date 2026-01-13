# Wippli Modifications to DocuSeal

This is a modified version of DocuSeal, maintained by Wippli for integration with the Wippli platform.

## Original Project

- **Project**: DocuSeal
- **Original Repository**: https://github.com/docusealco/docuseal
- **License**: GNU Affero General Public License v3.0 (AGPL-3.0)
- **Original Copyright**: DocuSeal contributors

## Modified Version

- **Modified By**: Wippli
- **Repository**: https://github.com/Wippli-Org/wippli-docuseal
- **Branch**: wippli-iframe-embedding
- **License**: GNU Affero General Public License v3.0 (AGPL-3.0)
- **Modification Date**: January 13, 2026

## Modifications Made

### 1. Iframe Embedding Support (January 2026)

**Purpose**: Enable DocuSeal to be embedded within Wippli's WipBoard component via iframe for seamless document signing workflows.

**Changes**:

#### config.ru (Lines 5-28)
- Added Rack middleware to remove `X-Frame-Options: SAMEORIGIN` header
- Added `Content-Security-Policy` with `frame-ancestors` directive allowing:
  - `*.wippli.ai`
  - `app.wippli.ai`
  - `dev.wippli.ai`
  - `localhost:*`
- Added diagnostic header `X-Wippli-Rack-v2` for verification

#### app/controllers/application_controller.rb (Lines 132-165)
- Modified `set_csp` method to remove `X-Frame-Options` header in response
- Added `frame_ancestors` policy to CSP allowing Wippli domains
- Added `remove_frame_options_for_wippli` method for after_action callback
- Added diagnostic header `X-Wippli-CSP-Fix` for verification

#### config/environments/production.rb (Lines 29-31)
- Deleted `X-Frame-Options` from Rails default headers configuration
- Added `Content-Security-Policy` with frame-ancestors for Wippli domains

#### Dockerfile (Line 99)
- Modified CMD to explicitly specify config.ru path: `/app/config.ru`
- Changed from `--dir /app` to explicit config path to ensure middleware loads

#### New Files Created

**Dockerfile.iframe-fix**
- Quick-patch Dockerfile for testing configuration changes
- Copies modified files into official DocuSeal image

**config/initializers/zzz_iframe_policy.rb**
- Rails initializer with inline middleware class `WippliIframeMiddleware`
- Alternative implementation for removing X-Frame-Options
- Named with `zzz_` prefix to ensure late loading order

**lib/remove_x_frame_options_middleware.rb**
- Standalone Rack middleware class
- Alternative implementation for header manipulation
- Includes diagnostic header `X-Wippli-Iframe-Fix`

## Technical Implementation

The primary implementation uses Rack middleware in `config.ru` to intercept HTTP responses at the outermost application layer (after Rails processing) and modify security headers before responses are sent to clients.

This approach allows DocuSeal's document signing interface to be embedded in iframes while maintaining security through Content-Security-Policy frame-ancestors restrictions.

## AGPL-3.0 Compliance

Per Section 13 of the GNU Affero General Public License v3.0, users interacting with this modified version through a network have the right to receive the Corresponding Source.

**Source Code Access**:
- Repository: https://github.com/Wippli-Org/wippli-docuseal
- Branch: wippli-iframe-embedding
- License: AGPL-3.0 (same as original)
- All modifications are publicly available at no charge

## Warranty Disclaimer

This modified version is provided "AS IS" without warranty of any kind, as specified in the GNU Affero General Public License v3.0, Section 15.

## Contact

For questions about these modifications:
- **Organization**: Wippli
- **Repository Issues**: https://github.com/Wippli-Org/wippli-docuseal/issues

For questions about the original DocuSeal project:
- **Original Repository**: https://github.com/docusealco/docuseal
