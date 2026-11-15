# Instantiated client only, no global configuration

The SDKs expose only an instantiated client. There is no `TeachMeHipaa.apiKey`
global or static configuration. Stripe users will look for one, but Stripe
itself is retiring it. Here a global would mean one shared token cache and one
bound Organization per process, which is wrong for any partner serving more
than one Organization.
