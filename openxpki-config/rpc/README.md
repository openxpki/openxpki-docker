# RPC Wrapper Setup

The `default.conf` now just holds the information to bootstrap the initial logger and setup localization.

Methods to request and revoke certificates are in the `enroll.conf` which will be used when you call e.g. https://mypki/rpc/enroll/RequestCertificate. This file is setup to uses the endpoint name as config anchor so it loads the policy settings for the workflows from `rpc.enroll` inside the used realm. If you need different settings you can just copy or even symlink the file to another name which creates a new endpoint.

As `default.conf` has no methods defined, any request made to an endpoint name that is not represented by a file will result in a *404 Not Found* error.

The `public.conf` holds an endpoint that can be used to search for certificates anonymously. There is no policy file in the backgroud.