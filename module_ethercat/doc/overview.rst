.. _ecat_overview_label:

Module EtherCAT
===============

EtherCAT is a real-time open communication protocol based on ethernet networks.
The standardization process is coordinated by the EtherCAT_ Technology Group.

This module allows a abstract access to the application layer of the EtherCAT
communication stack. The underlying device access and data transfere is
handled without the interaction of the device user application.

The EtherCAT access his implemented using a single thread. All communication
is done by channel communication and simple channel commands for the the
mailbox protocols. The PDOs are stored transparently for quick access.

The module supports the following protocols:

* PDO transfer
* CAN over EtherCAT (COE) with CiA402
* File over EtherCAT

.. _EtherCAT: http://www.ethercat.org
