# frozen_string_literal: true

# Wippli: Configure session cookies for cross-site iframe embedding.
# SameSite=None is required for session cookies to work inside iframes
# embedded on app.wippli.ai (cross-site context).
# Secure=true is required when using SameSite=None.
Rails.application.config.session_store :cookie_store,
                                       key: '_docuseal_session',
                                       same_site: :none,
                                       secure: true
