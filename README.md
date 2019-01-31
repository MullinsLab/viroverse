# Viroverse

Viroverse is a platform for the collection, storage, retrieval, and
analysis of experimental data for laboratory workflows. Developed
in-house for twelve years, it serves as the principal data store for HIV
sequencing experiments conducted in the Mullins Lab. Viroverse currently
houses tens of thousands of viral nucleotide sequences, together with
comprehensive metadata about their creation including PCR protocols, gel
images, subject clinical data, and more. Learn more about Viroverse at
<https://viroverse.washington.edu>.

The initial public release of Viroverse has many rough edges and very
little documentation. If you’re interested in using Viroverse in
production after trying it out in dev mode, please [reach out to
us](mailto:mullspt+cfar@uw.edu?subject=Viroverse) so we can engage
one-on-one to help you out.

## Help us fund Viroverse!

Development of Viroverse has been supported by the US National Institutes of
Health grants P01AI057005, R01AI111806, R01AI125026, R21AI122361, R37AI047734,
and R21AI087161 to Jim Mullins and P30AI027757 to the University of Washington
Center for AIDS Research.

**You can help us maintain funding for Viroverse** by [letting us
know](mailto:mullspt+cfar@uw.edu?subject=Viroverse) when you give Viroverse a
try or adopt it for use in your lab. We very much appreciate hearing from you.

## Getting Started

The easiest way to run Viroverse in a development environment is to start a
local virtual machine using [Vagrant](https://www.vagrantup.com) and
[VirtualBox](https://www.virtualbox.org). After installing VirtualBox and
Vagrant, running `vagrant up` in the root of a clone of this repository will
start and provision a development VM. This will take quite some time! The
provisioning script will install dependencies, create a database, and if all
goes well, create a user account named after your username on the host system.
To run the development server, log in to the VM with `vagrant ssh`, enter the
`/home/vagrant/viroverse` directory, and run `REMOTE_USER=username ./vv
plackup`, replacing `username` with your desktop login name. The application
should start and its web interface should be available by browsing to
<http://192.168.0.2:5000> from your desktop.
