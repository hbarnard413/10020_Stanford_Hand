.. _ecat_programming_label:

Using Module EtherCAT
=====================

One design goal for this module was easy usability to make the EtherCAT
communication as simple as possible.


There is the main header ethercat.h with the essential functions

:ecat_init(): initialize the module.

:ecat_handler(): start the ethercat communication and serve the data via the
  supported channels.

After the call to ecat_handler() the module is operational.


PDO Communication
-----------------
To receive the PDO data the user application have to poll the channel with the
command DATA_REQUEST. If data is available the hanlder will answer with the
number of data words and the datawords. Usually all configured PDOs.

A possible sequence could look like this:

::

                pdo_in <: DATA_REQUEST;
                pdo_in :> count;
                for (i=0; i<count; i++) {
                        unsigned tmp;
                        pdo_in :> tmp;
                        inBuffer[i] = tmp&0xffff;
                }

The module doesn't know anything about the data structure. So to make sense
from this field of words the user application has to know which data are
expected. This makes it possible to vary the PDO structure without changeing
the ethercat layer.

FoE Communication
-----------------
The FoE (File over EtherCAT) access is also channel based. The channel commands
FOE_FILE_* simulate the standard file access functions of a file system.
Or more precisely, a simple one file pseudo file system is integrated within
module ethercat.

A reading session would look like this (error handling is left out for readability):

::

   foe_comm <: FOE_FILE_OPEN;
   i=-1;
   do {
	   i++;
	   foe_comm <: (int)name[i];
   } while (name[i] != '\0');

   foe_comm <: FOE_FILE_READ;
   foe_comm <: BUFFER_SIZE; // so the module will transfer BUFFER_SIZE bytes

   foe_comm :> ctmp;
   if (ctmp == FOE_FILE_DATA) {
	foe_comm :> reply_size;
	for (i=0; i<reply_size; i++) {
		foe_comm :> ctmp;
		buffer[i] = (char)ctmp;
	}
   }

   foe_comm <: FOE_FILE_FREE; // if the file isn't used anylonger


CoE Communication
-----------------
To access the CAN Object Dictionary (OD) from the application the channel commands 

* CAN_GET_OBJECT
* CAN_SET_OBJECT
* CAN_OBJECT_TYPE
* CAN_MAX_SUBINDEX

are used. After each command the object index and subindex must be specified.
For easier conversion the macro

* CAN_OBJ_ADR

should be used.

To access the object with the index 0x1000 and subindex 0 (this is the device
type) one could use the following sequence

::

	can_chan <: CAN_GET_OBJECT;
	can_chan <: CAN_OBJ_ADDR(0x1000, 0);
	can_chan :> device_type;

If the object isn't accessible CAN_ERROR is returned instead of the object
value.
