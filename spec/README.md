Preparing for master slave integration tests
--------------------------------------------

You can set the integration specs up to run against a master slave setup by
running the included `setup-cluster` script.

To run specs in slave mode, set the SLAVE=1 when running tests:

  SLAVE=1 rake specs
