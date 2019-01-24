# Viroverse development tools

This directory contains various tooling for development of Viroverse, such as
dev VM configuration, schema model updating, test database refreshing, etc.

## Apache test server

From your development VM, you can spawn an Apache instance which proxies to the
Starlet backend in a manner very similar to production:

    ./vv devel/apache -u trsibley

This will start the servers with `trsibley` set as the authenticated user for
all requests and tail the access and error logs.  Ctrl-C to stop the server.
While it's running, you can use:

    ./vv scripts/restart-server

to restart just the backend.

The Apache instance listens on port 5000, but the VM sets up iptables rules
which redirect port 80 to port 5000 seamlessly.

### ViroBLAST

The Apache dev server also supports a local ViroBLAST instance, for when you
need to test out the [lab-internal ViroBLAST][] that's populated nightly with
sequences from Viroverse.

You must do the initial setup by hand: from within your viroverse.git clone on
the VM:

    git checkout hercules:/opt/git/viroverse-viroblast.git var/viroblast/
    mkdir var/viroblast/data/
    ./vv scripts/update-blast.pl
    # go get coffee

When the BLAST database is done being generated, you can then go to:

    http://your-vm/viroblast/


[lab-internal ViroBLAST]: https://viroverse.washington.edu/viroblast/
