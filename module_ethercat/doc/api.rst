
Project structure
=================

The main user API for the modle_ethecat component is found in ethercat.h.
For normal operation (PDO) it is sufficient to include only this file.

For direct access to the CAN Object Dictionary (OD) please include coecmd.h.
Here are the channel commands defined to manipulate individual objects within
the object dictionary.

For advanced FoE commands the file foe_chan.h should be used. Here are the
necessary channel commands defined to read and write files to transfere to
or from the host.

Symbolic constants
==================

.. doxygendefine:: DATA_REQUEST

Channel Commands for CAN Object Dictionary requests
---------------------------------------------------

.. doxygendefine:: CAN_GET_OBJECT
.. doxygendefine:: CAN_SET_OBJECT
.. doxygendefine:: CAN_OBJECT_TYPE
.. doxygendefine:: CAN_MAX_SUBINDEX

for a proper format of the CAN OD address please use

.. doxygendefine:: CAN_OBJ_ADR

Error code

.. doxygendefine:: CAN_ERROR
.. doxygendefine:: CAN_ERROR_UNKNOWN

Channel Commands for FoE transfer
---------------------------------

.. doxygendefine:: FOE_FILE_OPEN
.. doxygendefine:: FOE_FILE_READ
.. doxygendefine:: FOE_FILE_WRITE
.. doxygendefine:: FOE_FILE_CLOSE
.. doxygendefine:: FOE_FILE_SEEK
.. doxygendefine:: FOE_FILE_FREE
.. doxygendefine:: FOE_FILE_ACK
.. doxygendefine:: FOE_FILE_ERROR
.. doxygendefine:: FOE_FILE_DATA
.. doxygendefine:: FOE_FILE_READY

Types
=====

.. doxygenenum:: EC_MailboxProtocolTypes
.. doxygenstruct:: _ec_mailbox_header

API
===

.. doxygenfunction:: ecat_init

.. doxygenfunction:: ecat_handler

