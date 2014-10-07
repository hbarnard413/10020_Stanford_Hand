SOMANET EtherCAT firmware update module
======================================= 

:scope: General Use
:description: SOMANET EtherCAT firmware update module enables flashing SOMANET devices via EtherCAT
:keywords: SOMANET, etherCAT
:boards: XK-SN-1BH12-E, XK-SN-1BQ12-E, SOMANET Core-C22 


Key Features
------------

  * Firmware deployment/update via EtherCAT 

Description
-----------

The module implements a firmware update server over EtherCAT. The server acquires firmware binary file from the COM-EtherCat hardware module. A complete set of EtherCAT-enabled SOMANET nodes can be flashed from a Linux PC. Individual flashing of connected nodes is also supported. 

In order to access this module from your SOMANET slave application:

- Add module_fwupdate in your app makefile: ::

   USED_MODULES = module_ethercat_fwupdate

- Include the firmware update server header file into your code: ::

  #include <flash_somanet.h>

**Note:** The firmware binary file for flashing must be created either in the *xTIMEcomposer* or in the terminal using *.xe* application executable. 


