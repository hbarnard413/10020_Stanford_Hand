SOMANET Node Configuration
==========================

:scope: General Use
:description: the NODE CONFIGURATION is designed to define various hardware configurations possible with different SOMANET modules
:keywords: SOMANET
:boards: XK-SN-1BH12-E, XK-SN-1BQ12-E, SOMANET CORE C22

Key Features
------------

  * Code parameterization necessary for the various hardware configurations possible with SOMANET
  * Port mappings for all SOMANET Modules
 
Description
-----------

The module carries out the code parameterization necessary for the various hardware configurations possible with SOMANET. Define here your COM, Core and IFM boards. Create *nodeconfig.h* in your app's top level source directory and configure the node stack along the following lines::
      #define SOMANET_CORE c22
      #define SOMANET_COM ecat
      #define SOMANET_IFM dc100-rev-a

Refer to the *.inc* files included within this module to get a list of supported boards and include ioports.h in every source file that needs to access I/O ports

