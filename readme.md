# Reverse Proxy Container

## Docker Compose file
This Docker Compose file creates a single container and a network. 

### Images
The container runs the latest [Nginx](https://hub.docker.com/_/nginx) image.

### Resource limits
The container is restricted to 1 vCPU and 1GB of memory. These limits are simply to prevent the container from overwhemling the system it is running on. In normal operation it should run nowhere near these limits.

### Networks
By default, the container is connected to a single network. Applications that should be reachable by the reverse proxy should be connected to this network.

### Ports
The container forwards ports 80 and 443 from the host for HTTP and HTTPS connections respectively.

### Volumes
The container attaches three volumes; one file and two directories. The file is simply a basic `nginx.conf`, this may be extended as required.

The first directory is for additional configuration files. Files placed within this directory will be loaded through the `include` directive within `nginx.conf`.

The second directory is for the certificate files. Configuration files will need adjusting to use the correct path depending upon how the volume is mounted.

### Certificates
By default, a script to provision self-signed certificates with OpenSSL is provided. This can be removed when no longer required. Within the container, the certificate can be found at `/etc/nginx/ssl/fullchain.pem`, and the key can be found at `/etc/nginx/ssl/privkey.pem`.

If using Certbot, the entire `/etc/letsencrypt` directory should be mounted. This is because of how Certbot uses symlinks to ensure that the `live/<domain>/fullchain.pem` and `live/<domain>/privkey.pem` always refer to the latest certificates. Within the container, certificates would be found at `/etc/nginx/ssl/live/<domain>/fullchain.pem`, and keys would be found at `/etc/nginx/ssl/live/<domain>/privkey.pem`. Certbot should be configured to run `nginx -s reload` within the container after a certificate renews to ensure the certificate in use by Nginx is current.

## Configuration

### `nginx.conf`
The `user` directive sets the user that Nginx runs as.

The `worker_processes` directive sets how many cores Nginx is allowed to use. Setting this to `auto` will use all cores available. The `events.worker_connections` directive sets the number of connections each worker process can handle. Total concurrent requests can be approximated by the product of these two directives.

The `error_log` directive sets where errors should be logged and the severity level of items that should be included. Log levels in increasing severity: `info`, `notice`, `warn`, `error`, `crit`, `alert`, `emerg`.

The `pid` directive sets the location the master process writes its process ID to.

The `default_type` directive sets the default content type for responses that don't explicity define a content type. This can be set to any MIME type. The default is `text/plain`, but setting `application/octet-stream` ensures unknown files are downloaded instead of being rendered by the browser.

The `server_tokens` directive controls whether or not the version of Nginx is included in the `Server` response header. For production environments, this should be set to `off` to prevent disclosure of unnecessary information.

The `keepalive_timeout` directive controls how many seconds Nginx will keep the connection alive to reduce the overhead that would be required for a client to renegotiate a connection. The second value sets the `Keep-Alive` response header. It is recommended to set the second value a few seconds lower than the first value to account for potential latency between the client and the server.

### `conf.d/default.conf`
The `listen <port> default_server` section informs Nginx that if no other server is matched on the given port, then this server should be used. This behaviour is used to define default behaviours on ports 80 and 443.

The default behaviour on port 80 is to redirect the request to HTTPS. If alternative behaviour is desired, this can be defined in a separate configuration file.

The default behaviour on port 443 is to return HTTP code 444. This is an unofficial code specific to Nginx. It closes the connection without a reason. We can't only accept requests to known hostnames, because we must first accept to request to discover which hostname it is for. If a request comes in for an unknown hostname then the connection is terminated as soon as this is established.

The only exception to this behaviour on port 443 is for the `/status` location. If this is requested, an HTTP code of 200 will be returned. This is to be used for server and network health checks. It simply indicates whether or not Nginx is online and responding to requests. Application-specific health checks should be built into the configuration file for a given application.

Sane defaults for SSL configuration options can be generated [here](https://ssl-config.mozilla.org/). HSTS and OCSP Stapling should only be used with valid certificates. HSTS sets a header which tells the client to reject the connection if an invalid certificate is presented. OCSP Stapling allows the server to present the CA certificates alongside the main certificate to prevent the client from having to look up the CA certificate themselves. For Certbot, this is the `live/<domain>/chain.pem` certificate file.
