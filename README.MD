sw-paas-check reviews the Shopware PaaS configuration.

It must run from a Shopware PaaS environment. It can be added as a post-deploy hook.

5 tests are currently included:
* Shopware/Core version check: warn if this is not the latest version
* Fastly VCL snippets: warn if they don't exist on the Fastly service (require the Fastly CLI)
* Fastly status: warn if Fastly is not enabled in the Shopware configuration
* Fastly soft-purges: warn if the Fastly soft-purges are not enabled
* CSRF: warn if Shopware/Core version is < 6.5 and CSRF is enabled and not configured to ajax