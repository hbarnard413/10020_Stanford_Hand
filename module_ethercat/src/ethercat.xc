/**
 * @file ethercat.xc
 * @brief  A simple configuration file for the ethercat module to
 *         activate or disable specific features.
 */

#include "ethercat.h"
#include "alstate.h"
#include "foefs.h"
#include "foe.h"
#include "eoe.h"
#include "coe.h"
#include "coecmd.h"
#include "canod/canod.h"

#include <platform.h>
#include <xs1.h>
#include <print.h> /* FIXME remove after debug */

#define ET_USER_RAM       0x0f80
#define ET_HEADER_SZ      6
#define MAX_BUFFER_SIZE    128
#define ETHERCAT_HAS_FOE
#define EC_CS_SET()       ecatCS <: 0
#define EC_CS_UNSET()     ecatCS <: 1
#define EC_RD_SET()       ecatRD <: 0
#define EC_RD_UNSET()     ecatRD <: 1
#define EC_WR_SET()       ecatWR <: 0
#define EC_WR_UNSET()     ecatWR <: 1

#define EC_DATA_READ(x)   ecatData <: x
#define EC_DATA_WRITE(x)  ecatData :> x

#define EC_BUSY(x)        ecatBUSY :> x
#define EC_IRQ(x)         ecatIRQ :> x

#define EC_ADDRESS(x)     ecatAddress <: x

#define BYTESWAP_16(x)   (((x>>8)&0x00ff) | ((x<<8)&0xff00))

/* --- handlers for currently active services --- */
#define SERVICE_MBOX_IS_ACTIVE(x)    (x&0x01)
#define SERVICE_PDORX_IS_ACTIVE(x)   ((x>>1)&0x01)
#define SERVICE_PDOTX_IS_ACTIVE(x)   ((x>>2)&0x01)

#define SERVICE_MBOX_SET(x,v)        (x = (x&~0x01) | (v&0x01))
#define SERVICE_PDORX_SET(x,v)       (x = (x&~0x02) | ((v<<1)&0x02))
#define SERVICE_PDOTX_SET(x,v)       (x = (x&~0x04) | ((v<<2)&0x04))

static int g_services = 0; /* bit0: mailbox active; bit1: rx process data active; bit 2: tx process data active */

/* --- sync manager defines and global variables --- */

#define EC_SYNCM_COUNT  8 /* # of syncmanager channels for et1100 */
#define EC_SYNCM_BASE   0x0800
#define EC_SYNCM_GET_CONTROL_STATUS(manid)     ((EC_SYNCM_BASE+manid*8)+0x4)

#define SYNCM_BUFFER_MODE         0x00
#define SYNCM_MAILBOX_MODE        0x02
#define SYNCM_BUFFER_MODE_READ    (SYNCM_BUFFER_MODE | 0x04)
#define SYNCM_MAILBOX_MODE_READ   (SYNCM_MAILBOX_MODE | 0x04)
#define SYNCM_BUFFER_MODE_WRITE   SYNCM_BUFFER_MODE
#define SYNCM_MAILBOX_MODE_WRITE  SYNCM_MAILBOX_MODE


struct _syncm {
	uint16_t address;
	uint16_t size;
	uint8_t control;
		/* uint8_t type; / * buffer | mailbox mode */
		/* uint8_t direction / * ECAT:r PDI:w  OR ECAT:w PDI:r */
	uint8_t status;
	uint8_t activate;
	uint8_t pdi_ctrl;
};

struct _syncm manager[EC_SYNCM_COUNT];

#if 0
/* FIXME use this instead of the SyncManager struct above! I.e. one for coe, eoe, foe each. */
struct _mbox {
	uint16_t rd_address;
	uint16_t rd_size;
	uint16_t wr_address;
	uint16_t wr_size;
	char rd_full;
	char wr_full;
};
#endif

/* --- fmmu defines and global variables --- */

#define EC_FMMU_BASE    0x0600
#define EC_FMMU_COUNT   8

struct _fmmu {
	uint32_t logical_start;
	uint16_t offset;
	uint8_t reg_start_bit;
	uint8_t reg_stop_bit;
	uint16_t physical_start_address;
	uint8_t phy_start_bit;
	uint8_t reg_type;
	uint8_t reg_activate;
};

struct _fmmu fmmu[EC_FMMU_COUNT];


/* --- in/output ports --- */

/* FIXME add defines to *.xn file */
on stdcore[0]: out port ecatCS = XS1_PORT_1M;
on stdcore[0]: out port ecatRD = XS1_PORT_1L;
on stdcore[0]: out port ecatWR = XS1_PORT_1K;
on stdcore[0]: in  port ecatBUSY = XS1_PORT_1J;
on stdcore[0]: in  port ecatIRQ = XS1_PORT_1I;
//on stdcore[0]: in port ecatEEPROM = XS1_PORT_???;
/* reset ??? */
on stdcore[0]: out port ecatRST = XS1_PORT_1F;


on stdcore[0]: out port ecatAddress = XS1_PORT_16B;
on stdcore[0]:     port ecatData = XS1_PORT_16A;

static uint16_t escStationAddress;
static uint16_t escStationAddressAlias;

static uint16_t rxErrorCounter;
static uint8_t ecatProcError;
static uint8_t pdiError;

static int foeReplyPending;
static int eoeReplyPending;
static int coeReplyPending;

/**
 * @brief send packages to the connected channel endpoint.
 */
static void ecat_send_handler(chanend c_handler, uint16_t packet[], uint16_t size)
{
	c_handler <: (unsigned int)size; /* transmit size first so the handler knows the number of bytes that follow */
	for (int i=0; i<size; i++) {
		c_handler <: (unsigned int)packet[i];
	}
}

/* low level read of ET1100 register */
static uint16_t ecat_read(uint16_t address)
{
	timer t;
	unsigned int time;
	uint8_t busy;
	uint16_t adr;
	uint16_t data = 0x0000;

	adr = BYTESWAP_16(address);

	ecatAddress <: adr; /* set address */
	ecatRD <: 0; /* set read active */

	/* wait until busy is released */
	ecatBUSY :> busy;

	/* FIXME should wait until busy becomes busy (1->0) ? */
	while (busy == 1)
		ecatBUSY :> busy;
	/* /
	while (busy == 0)
		ecatBUSY :> busy;
	 */

	/* wait until data are valid */
	t :> time;
	t when timerafter(time+30) :> void; /* this is about 300ns */

	ecatData :> data; /* read data word */

	ecatRD <: 1; /* read sequence finished */

	/* satisfy t_read_delay */
	t :> time;
	t when timerafter(time+1) :> void; /* this is about 10ns */

#if 0
	if (address>=0x1000) {
		printstr("Access to process ram\n");
	}
	if ((address>=0x1000) && ((data&0x2000) == 0)) {
		printstr("Address/Data: ");
		printhex(address);
		printstr("/");
		printhexln(data);
	}
#endif

	return data;
}

static unsigned int ecat_read_block(uint16_t addr, uint16_t len, uint16_t buf[])
{
	unsigned int wordcount = 0;
	uint16_t address = addr;

	while (wordcount<len) {
		buf[wordcount] = ecat_read(address);
		wordcount++;
		address+=2;
	}

	return wordcount;
}

/* low level write to ET1100 register */
static int ecat_write(uint16_t address, uint16_t word)
{
	timer t;
	unsigned int time;
	uint16_t adr;

	address = address&0xffff;
	adr = BYTESWAP_16(address);

	ecatAddress <: adr;
	ecatData <: word;
	ecatWR <: 0;

	t :> time;
	t when timerafter(time+2) :> void; /* wait 20ns  to satisfy t_WR_active */

	ecatWR <: 1;

	t:>time;
	t when timerafter(time+2) :> void; /* wait t_wr_delay >= 10ns to make sure the next WR access is in time. */

	return 0;
}

/* write block of values to ram
 *
 * param addr   start address where data should go
 * param len    length of buf[] in 16-bit words
 * param buf[]  buffer of values to write
 * return number of words written
 */
static unsigned int ecat_write_block(uint16_t addr, uint16_t len, uint16_t buf[])
{
	unsigned int wordcount = 0;
	uint16_t address = addr;

	while (wordcount<len) {
		ecat_write(address, buf[wordcount]);
		wordcount++;
		address+=2;
	}

	return wordcount;
}

/* FIXME check if split up in ecat_read_buffer() and ecat_read_mailbox() makes sense. */
static int ecat_process_packet(uint16_t start, uint16_t size, uint8_t type,
				chanend c_coe, chanend c_eoe, chanend c_eoe_sig, chanend c_foe, chanend c_pdo)
{
	const uint8_t mailboxHeaderLength = 3; /* words */
	uint16_t buffer[MAX_BUFFER_SIZE];
	int error = AL_NO_ERROR;
	uint16_t offset=0;

	uint16_t wordCount;
	uint16_t packetWords;

	struct _ec_mailbox_header h;

	if ((size&0x0001) == 0) { /* size is even */
		packetWords = size/2;
	} else {
		packetWords = (size+1)/2;
	}

	wordCount = (MAX_BUFFER_SIZE<packetWords) ? MAX_BUFFER_SIZE : packetWords;

	switch (type) {
	case SYNCM_BUFFER_MODE:
		//printstr("DEBUG ecat_process_packet(): processing Buffer Mode\n");
		ecat_read_block(start, wordCount, buffer);
		ecat_send_handler(c_pdo, buffer, wordCount);

		break;

	case SYNCM_MAILBOX_MODE:
		ecat_read_block(start, mailboxHeaderLength, buffer);          // read mailbox header
		h.length = buffer[0];
		h.address = buffer[1];
		h.channel = buffer[2]&0x003f;
		h.priority = (buffer[2]>>6)&0x0003;
		h.type = (buffer[2]>>8)&0x000f;
		h.control = (buffer[2]>>12)&0x0007;

		if (wordCount < (h.length/2)) {
			wordCount = wordCount;
			printstr("Error length in mailbox header is too large: 0x");
			printhexln(h.length);
			error = AL_ERROR;
		} else {
			wordCount = h.length/2;
		}

		offset = start+(mailboxHeaderLength*2);
		ecat_read_block(offset, packetWords-mailboxHeaderLength/*wordCount*/, buffer);  // read mailbox data
			/* FIXME should read wordCount (== h.length/2) from EC mailbox memory area */
			/* FIXME check return vlaue (== wordCount) */

		switch (h.type) {
		case EOE_PACKET:
			//printstr("DEBUG ethercat: received EOE packet.\n");
			//ecat_send_handler(c_eoe, buffer, wordCount);
			//printstr("[DEBUG] EoE packet received\n");
#if ETHERCAT_HAS_EOE
			eoe_rx_handler(c_eoe, c_eoe_sig, buffer, wordCount);
#else
			error = AL_MBX_EOE;
#endif
			break;

		case COE_PACKET:
			//printstr("DEBUG ethercat: received COE packet.\n");
			//ecat_send_handler(c_coe, buffer, wordCount);
			//error = AL_MBX_COE;
			coeReplyPending = coe_rx_handler(c_coe, (buffer, unsigned char[]), (unsigned)h.length);
			break;

		case FOE_PACKET:
			//printstr("DEBUG ethercat: received FOE packet, start processing.\n");
			//ecat_send_handler(c_foe, buffer, wordCount);
#ifdef ETHERCAT_HAS_FOE
			foeReplyPending = foe_parse_packet(c_foe, buffer, wordCount);
#else
			error = AL_MBX_FOE;
#endif
			break;

		case SOE_PACKET: /* ignored unsupported */
			error = AL_MBX_SOE;
			break;

		case VENDOR_BECKHOFF_PACKET: /* ignored unsupported */
			error = AL_MBX_VOE;
			break;

		case VOE_PACKET: /* ignored unsupported */
			/* FIXME: [FOE as VOE] due to the need for a quick solution the FOE channel is used as VOE channel */
			//ecat_send_handler(c_foe, buffer, wordCount);
			error = AL_MBX_VOE;
			break;

		case ERROR_PACKET:
			printstr("Error packet received: ");
			printhexln(h.type);
			error = AL_ERROR;
			break;

		default:
			printstr("found unknown package: ");
			printhexln(h.type);
			error = AL_ERROR;
			break;
		}
		break;
	}

	return error;
}

/* Send mailbox packet
 *
 * start_address  start address of memory area of mailbox
 * max_size       maximum size of mailbox memory area
 * type           type of mailbox message
 * buffer[]       buffer to copy to mailbox memory area
 * sendsize       size of mailbox data in bytes
 * return AL_NO_ERROR or AL_ERROR
 */
static int ecat_mbox_packet_send(uint16_t start_address, uint16_t max_size, int type,
					uint16_t buffer[], uint16_t sendsize)
{
	uint16_t sendbuffer[256];
	uint16_t temp = 0;
	unsigned int pos = 0;
	uint16_t size = max_size/2; /* max_size in bytes, size in words */
	uint16_t sent = 0;

	struct _ec_mailbox_header h;

	h.length = sendsize;
	h.address = escStationAddress;
	h.channel = 0;
	h.priority = 1;
	h.type = type;
	h.control = 1; /* start value 1, 0 is reserved */

	sendbuffer[pos++] = h.length;
	sendbuffer[pos++] = h.address;
	sendbuffer[pos] = h.channel&0x003f;
	temp = h.priority&0x3;
	sendbuffer[pos] |= (temp<<6);
	temp = h.type&0xf;
	sendbuffer[pos] |= (temp<<8);
	temp = h.control&0x7;
	sendbuffer[pos] |= (temp<<12);
	pos++;

	for (int i=0; i<(sendsize+1)/2; i++, pos++) {
		sendbuffer[pos] = buffer[i];
	}

	/* Padding: The last byte in SyncM mailbox buffer must be written to trigger send signal */
	for (int i=pos; i<size; i++) {
		sendbuffer[i] = 0x00;
	}

	sent = ecat_write_block(start_address, size, sendbuffer);
	if ((sent - size) > 1) {
		printstr("Error wrong return size\n");
		return AL_ERROR;
	}

	return AL_NO_ERROR;
}

static void ecat_update_error_counter(void)
{
	uint16_t data = 0;

	rxErrorCounter = ecat_read(0x0300);

	data = ecat_read(0x030c);
	ecatProcError = data & 0xff;
	pdiError = (data>>8) & 0xff;
}

/* ----- sync manager ----- */

static void ecat_read_syncm(void)
{
	uint16_t address = EC_SYNCM_BASE;
	uint16_t data = 0;

	for (int i=0; i<EC_SYNCM_COUNT; i++) {
		address = EC_SYNCM_BASE+i*8;

		data = ecat_read(address);
		manager[i].address = data&0xffff;

		address+=2;
		data = ecat_read(address);
		manager[i].size = data&0xffff;

		address+=2;
		data = ecat_read(address);
		manager[i].control = data&0xff;
		manager[i].status = (data>>8)&0xff;

		address+=2;
		data = ecat_read(address);
		manager[i].activate = data&0xff;
		manager[i].pdi_ctrl = (data>>8)&0xff;
	}
}

static void ecat_clear_syncm(void)
{
	for (int i=0; i<EC_SYNCM_COUNT; i++) {
		manager[i].address = 0;
		manager[i].size = 0;
		manager[i].control = 0;
		manager[i].status = 0;
		manager[i].activate = 0;
		manager[i].pdi_ctrl = 0;
	}
}

/* ----- fmmu ----- */

static int ecat_read_fmmu_config(void)
{
	int activeFmmu=0;
	uint16_t address = EC_FMMU_BASE;
	uint16_t data;
	uint32_t tmp;

	for (int i=0; i<EC_FMMU_COUNT; i++) {
		address = EC_FMMU_BASE+i*8;

		tmp = ecat_read(address);
		fmmu[i].logical_start = tmp;
		tmp = ecat_read(address+2);
		fmmu[i].logical_start = ((tmp<<16)&0xffff0000) | fmmu[i].logical_start;

		fmmu[i].offset = ecat_read(address+4);

		data = ecat_read(address+6);
		fmmu[i].reg_start_bit = data&0xff;
		fmmu[i].reg_stop_bit = (data>>8)&0xff;

		fmmu[i].physical_start_address = ecat_read(address+8);

		data = ecat_read(address+10);
		fmmu[i].phy_start_bit = data&0xff;
		fmmu[i].reg_type = (data>>8)&0xff;

		data = ecat_read(address+12);
		fmmu[i].reg_activate = data&0x01;
		activeFmmu += fmmu[i].reg_activate;
	}

	return activeFmmu;
}

static void ecat_clear_fmmu(void)
{
	for (int i=0; i<EC_FMMU_COUNT; i++) {
		fmmu[i].logical_start = 0;
		fmmu[i].logical_start = 0;
		fmmu[i].offset = 0;
		fmmu[i].reg_start_bit = 0;
		fmmu[i].reg_stop_bit = 0;
		fmmu[i].physical_start_address = 0;
		fmmu[i].phy_start_bit = 0;
		fmmu[i].reg_type = 0;
		fmmu[i].reg_activate = 0;
	}
}

/* ----- al state machine ----- */

/**
 * @brief State machine for application layer.
 *
 * As sideeffect the global g_services is set accordingly.
 * FIXME handle BOOTSTRAP separately
 *
 * @param reqState   master requested state
 * @return  new state, either reqstate is confirmed or fallback.
 * @return  0 if no error occures, error word (@see AL error codes)
 */
{uint16_t, uint16_t} al_state_machine(uint16_t reqState, uint16_t currentState)
{
	uint16_t newstate = 0;
	uint16_t error = AL_NO_ERROR;
	reqState = reqState&0xf;

	switch (reqState) {
	case AL_STATE_INIT:
		ecat_clear_fmmu();
		ecat_clear_syncm();
		newstate = AL_STATE_INIT;
		error = AL_NO_ERROR;
		SERVICE_MBOX_SET(g_services, 0);
		SERVICE_PDORX_SET(g_services, 0); // no pdo communication
		SERVICE_PDOTX_SET(g_services, 0); // no pdo communication
		break;

	case AL_STATE_BOOTSTRAP: /* possible use for configuration (FoE) */
		newstate = AL_STATE_INIT|AL_STATE_ERRORBIT;
		error = AL_BOOTSTRAP_NOT_SUPPORTED;
		break;

	case AL_STATE_PREOP:
		/* master configured DL-Address registers and SyncM registers */
		ecat_clear_fmmu();
		ecat_read_syncm();
		newstate = AL_STATE_PREOP;
		error = AL_NO_ERROR;
		SERVICE_MBOX_SET(g_services, 1);
		SERVICE_PDORX_SET(g_services, 0); // no pdo communication
		SERVICE_PDOTX_SET(g_services, 0); // no pdo communication
		break;

	case AL_STATE_SAFEOP:
		/* master conf. parameters using mailbox (process data);
		 * master configures SyncM channels for process data and fmmu channels
		 * starting input PDOs
		 */
		ecat_read_syncm(); /* reread for process data */
		SERVICE_MBOX_SET(g_services, 1);

		if (ecat_read_fmmu_config() < 1) {
			//newstate = currentState; /* FIXME stay on state and ignore FMMU configure if fallback from higher sate */
			//error = AL_INVALID_INPUT_MAPPING;
			SERVICE_PDORX_SET(g_services, 0); // no pdo communication
			SERVICE_PDOTX_SET(g_services, 0); // no pdo communication
		} else {
			SERVICE_PDORX_SET(g_services, 1); // receive pdo
			SERVICE_PDOTX_SET(g_services, 0); // but don't send
		}
		newstate = AL_STATE_SAFEOP;
		error = AL_NO_ERROR;
		break;

	case AL_STATE_OP:
		/* slave now fully operational, input and output PDOs and mailbox communication */
		ecat_read_syncm(); /* reread for process data */
		SERVICE_MBOX_SET(g_services, 1);

		if (ecat_read_fmmu_config() < 2) {
			//newstate = currentState; /* FIXME stay on state and ignore FMMU configure if fallback from higher sate */
			//error = AL_INVALID_OUTPUT_MAPPING;
			SERVICE_PDORX_SET(g_services, 0); // no pdo communication
			SERVICE_PDOTX_SET(g_services, 0); // no pdo communication
		} else {
			SERVICE_PDORX_SET(g_services, 1);
			SERVICE_PDOTX_SET(g_services, 1);
		}
		newstate = AL_STATE_OP;
		error = AL_NO_ERROR;
		break;

	default:
		/* errornous state: set AL_REG_STATUS_CODE (error) and stop */
		newstate = currentState|AL_STATE_ERRORBIT;
		error = AL_ERROR;
		break;
	}

	if (error != AL_NO_ERROR)
		newstate |= 0x0010; /* set error indicator */

	return {newstate, error};
}

static int ecat_read_fmmu(uint16_t data[])
{
	unsigned int wordCount=0;
	uint16_t address;

	for (int i=0; i<EC_FMMU_COUNT; i++) {
		if (fmmu[i].reg_type == 0x01 && fmmu[i].reg_activate == 1) {
			if ((fmmu[i].offset&0x0001) == 1) /* offset is odd */
				wordCount = (fmmu[i].offset+1) / 2;
			else
				wordCount = fmmu[i].offset /2;

			address = fmmu[i].physical_start_address;
			for (int j=0; j<wordCount; j++) {
				data[j] = ecat_read(address);
				address+=2;
			}
		}
	}

	return 0;
}

static int ecat_write_fmmu(uint16_t data[])
{
	uint16_t wordCount=0;
	uint16_t address;

	for (int i=0; i<EC_FMMU_COUNT; i++) {
		if (fmmu[i].reg_type == 0x02 && fmmu[i].reg_activate == 1) {
			if ((fmmu[i].offset&0x00001) == 1) /* offset is odd */
				wordCount = (fmmu[i].offset+1) /2;
			else
				wordCount = fmmu[i].offset /2;

			address = fmmu[i].physical_start_address;
			for (int j=0; j<wordCount; j++) {
				ecat_write(address, data[j]);
				address+=2;
			}

		}
	}

	return 0;
}

int ecat_get_fmmu(uint16_t data[])
{
	return 0;
}

int ecat_put_fmmu(uint16_t data[])
{
	return 0;
}

int ecat_init(void)
{
	timer t;
	unsigned time;

	/* DEBUG output of current module version */
	printstr("EtherCAT Module ");
	printstrln(ecat_version);

	ecatCS <: 1;
	ecatWR <: 1;
	ecatRD <: 1;
	ecatData <: 0x0000;

	ecatRST <: 0;

	for (int i=0; i<EC_FMMU_COUNT; i++) {
		fmmu[i].logical_start = 0;
		fmmu[i].offset = 0;
		fmmu[i].reg_start_bit = 0;
		fmmu[i].reg_stop_bit = 0;
		fmmu[i].physical_start_address = 0;
		fmmu[i].phy_start_bit = 0;
		fmmu[i].reg_type = 0;
		fmmu[i].reg_activate = 0;
	}

	for (int i=0; i<EC_SYNCM_COUNT; i++) {
		manager[i].address = 0;
		manager[i].size = 0;
		manager[i].control = 0;
		manager[i].status = 0;
		manager[i].activate = 0;
		manager[i].pdi_ctrl = 0;
	}

	t :> time;
	t when timerafter(time+10000) :> void; /* after 100ms the EEPROM should be loaded */

#if 0
	/* currently not available */
	while (!loaded) {
		ecatEEPROM :> loaded;
		t :> time;
		t when timerafter(time+1) :> void;
	}
#endif

	EC_CS_SET();
	ecat_write(AL_REG_STATUS_CODE, (uint16_t)AL_NO_ERROR);

#if 0
	while (1) {
		data = ecat_read(0x0110 /* ESC DL Status */);
		printstr("ESC DL Status: ");
		printhexln(data);

		if ((data&0x0001) > 0) {
			printstr("EEPPROM loaded, PDI operational\n");
			break; /* finish, continue with operational */
		}
	}

	/* read PDI configuration * /
	data = ecat_read(0x150);
	printstr("Register 0x150: ");
	printhexln(data);
	// */

	data = ecat_read(0x0152);
	printstr("Register 0x152: ");
	printhexln(data);
#endif

	EC_CS_UNSET();

	/* init foefs and foe */
	foefs_init();
	foe_init();
	foeReplyPending=0;
	eoeReplyPending=0;
	coeReplyPending=0;

	coe_init();

	return 0;
}

int ecat_reset(void)
{
	return -1;
}

/* FIXME change the chanends so the function declaration will look like this:
 * void ecat_handler(chanend c_ecats_rx[], chanend c_ecats_tx[], chanend ?c_ecats_sig[], int numsignals);
 *
 * enum eChanNum {
 *    CHAN_COE=0
 *    ,CHAN_EOE
 *    ,CHAN_FOE
 *    ,CHAN_PDO
 *    ,CHAN_VOE
 * };
 *
 */
#define PDO_BUFFER    64

void ecat_handler(chanend c_coe_r, chanend c_coe_s,
			chanend c_eoe_r, chanend c_eoe_s, chanend c_eoe_sig,
			chanend c_foe_r, chanend c_foe_s,
			chanend c_pdo_r, chanend c_pdo_s)
{

	timer tpdo;
	unsigned int pdotime;
	unsigned int pdotimeprev;

	uint16_t data = 0;

	uint16_t pdo_inbuf[PDO_BUFFER];
	uint16_t pdo_outbuf[PDO_BUFFER]; /* FIXME remove magic number and support generic size of pdo buffer */
	unsigned pdo_outsize = 0;
	unsigned pdo_insize = 0;

	uint16_t al_state = AL_STATE_NOOP;
	uint16_t al_error = AL_NO_ERROR;
	uint16_t packet_error = AL_NO_ERROR;

	uint16_t out_buffer[256];
	uint16_t out_size = 0;
	uint16_t out_type = ERROR_PACKET;
	unsigned int otmp = 0;
	int pending_buffer = 0; /* no buffer to send */
	int pending_mailbox = 0; /* no mailbox to send */

	unsigned lastwritten_inbuffer = 3;
	unsigned lastwritten_outbuffer = 3;


	eoe_init();

	for (int i=0;i<PDO_BUFFER;i++) {
		pdo_inbuf[i] = 0;
		pdo_outbuf[i] = 0;
	}

	tpdo :> pdotime;
	pdotimeprev = pdotime;

	EC_CS_SET();
	while (1) {
		ecat_update_error_counter();

		data = ecat_read(AL_REG_EVENT_REQUEST_LOW);
		if (data & AL_CONTROL_EVENT) {
			data = ecat_read(AL_REG_CONTROL);
			{al_state, al_error} = al_state_machine(data&0x001f, al_state); /* bits 15:5 are reserved */
			ecat_write(AL_REG_STATUS, al_state);
			ecat_write(AL_REG_STATUS_CODE, al_error);
		}

		/* check if state transission errors occured */
		if ((al_state&0x10) > 0 || al_error != AL_NO_ERROR) {
			continue;
		}

		/* If preop state isn't reached there is no need to process mailbox/buffer communication. */
		if ((al_state&0xf) < AL_STATE_PREOP) {
			escStationAddress = ecat_read(0x0010);
			escStationAddressAlias = ecat_read(0x0012);
			continue;
		}

		for (int i=0; i<8; i++) {
			packet_error = AL_NO_ERROR;

			if ((manager[i].activate&0x01) == 1) { /* sync manager is active */
				data = ecat_read(EC_SYNCM_GET_CONTROL_STATUS(i));
				manager[i].control = data&0xff;
				manager[i].status = (data>>8)&0xff;

				switch (manager[i].control&0x0f) {
				case SYNCM_BUFFER_MODE_READ:
					if (SERVICE_PDORX_IS_ACTIVE(g_services)) {
						if ( (manager[i].status&0x1) && ( lastwritten_inbuffer ^ ((manager[i].status>>4)&0x03))) {
							pdo_insize = ecat_read_block(manager[i].address, ((manager[i].size+1)/2), pdo_inbuf);

#if 0 /* DEBUG output */
							for (int k=0; k<pdo_insize; k++) {
								printstr("pdo received: "); printhexln(pdo_inbuf[k]);
							}
#endif
							lastwritten_inbuffer = (manager[i].status>>4)&0x03;
						}
					}
					break;

				case SYNCM_BUFFER_MODE_WRITE:
					/* send packets pending? */
					if (SERVICE_PDOTX_IS_ACTIVE(g_services)) {
						tpdo :> pdotime;
						if (((pdotime-pdotimeprev) >= 100) /*&& (lastwritten_outbuffer != (manager[i].status>>4)&0x03)*/) {
							//printstr("Write Buffer SyncM: ");
							//printintln(i);
							/* FIXME check return value */
							ecat_write_block(manager[i].address, pdo_outsize, pdo_outbuf); /* out_size: byte -> word */
							lastwritten_outbuffer = (manager[i].status>>4)&0x03;
							pdotimeprev = pdotime;
						}
					}
					break;

				case SYNCM_MAILBOX_MODE_READ:
					//printstr("[DEBUG:] Mailbox ready to read.\n");
					if (SERVICE_MBOX_IS_ACTIVE(g_services) && ((manager[i].status & 0x08) != 0)) { /* mailbox full */
						//printstr("Read Mailbox SyncM: ");
						//printintln(i);
						//printstr("Mailbox address and size:\n");
						//printhexln(manager[i].address);
						//printhexln(manager[i].size);
						packet_error = ecat_process_packet(manager[i].address, manager[i].size, SYNCM_MAILBOX_MODE,
									c_coe_s, c_eoe_s, c_eoe_sig, c_foe_s, c_pdo_s);
					}
					break;

				case SYNCM_MAILBOX_MODE_WRITE:
					/* send packets pending? */
					if (SERVICE_MBOX_IS_ACTIVE(g_services) && pending_mailbox == 1 /*&& manager[i].status == 0*/) {
						packet_error = ecat_mbox_packet_send(manager[i].address, manager[i].size,
									 out_type, out_buffer, out_size);
						pending_mailbox=0;
					}

					break;

				}
			}

			if (packet_error != AL_NO_ERROR) { /* FIXME implement valid error handling */
				//printstr("Packet error: 0x"); printhexln(packet_error);
			}
		}

		/* read incoming filehandles, if no mailbox is pending! */
		if (pending_mailbox != 1) {
			select {
			case c_coe_r :> otmp :
				switch (otmp) {
				case CAN_GET_OBJECT:
					{
					unsigned index;
					unsigned value;
					unsigned type;

					c_coe_r :> index;

					canod_get_entry((index>>8), index&0xff, value, type);
					c_coe_r <: value;
					}
					break;

				case CAN_SET_OBJECT:
					{
					unsigned index;
					unsigned value;
					unsigned type = 0;

					c_coe_r :> index;
					c_coe_r :> value;

					canod_set_entry((index>>8), index&0xff, value, type);
					c_coe_r <: value;
					}
					break;

				case CAN_OBJECT_TYPE:
					{
					unsigned index;
					unsigned value;
					unsigned type;

					c_coe_r :> index;

					canod_get_entry((index>>8), index&0xff, value, type);
					c_coe_r <: type;
					}
					break;

				case CAN_MAX_SUBINDEX:
					c_coe_r <: CAN_ERROR_UNKNOWN; /* FIXME implement */
					break;

				default:
					c_coe_r <: CAN_ERROR_UNKNOWN;
					break;
				}
#if 0
				printstr("DEBUG: processing outgoing CoE packets\n");
				out_type = COE_PACKET;
				out_size = (otmp&0xffff)*2; /* otmp is number of 16-bit words,  */
				printhexln(out_size);
				for (int i=0; i<(out_size+1)/2; i++) {
					c_coe_r :> otmp;
					out_buffer[i] = otmp&0xffff;
				}
				pending_mailbox=1;
#endif
				break;

			case c_eoe_r :> otmp :
				/* FIXME currently not supported!!!
				coeReplyPending = coe_tx_handler(c_eoe_r, otmp);
				if (coeReplyPending==1) {
					printstr("[DEBUG EoE] packet waits for transmit\n");
				}
				 */
				break;

			case c_foe_r :> otmp :
				//printstr("DEBUG: receive FoE command (e.g. file access)\n");
				foe_file_access(c_foe_r, otmp);
				#if 0
				out_size = otmp&0xffff;
				//printstr("DEBUG: read: "); printhexln(out_size);
				//printstr("> ");
				out_type = FOE_PACKET;
				for (i=0; i<out_size; i++) {
					c_foe_r :> otmp;
					out_buffer[i] = otmp&0xffff;
					//printhex(out_buffer[i]);
				}
				foe_command = otmp;

				if (foe_request(out_buffer) == 1) {
					out_size = foe_get_reply(out_buffer);
					pending_mailbox=1;
				}
				#endif
				break;

			case c_pdo_r :> otmp :
				//printstr("DEBUG: regular processing outgoing PDO packets\n");
				pdo_outsize = otmp&0xffff;
				out_type = 0; // no mailbox packet, unused here!
				for (int i=0; i<pdo_outsize; i++) {
					c_pdo_r :> otmp;
					pdo_outbuf[i] = otmp&0xffff; /* FIXME asumption 16-bit values */
				}
				pending_buffer=1;
				break;

			case c_pdo_s :> otmp :
				if (otmp == DATA_REQUEST) {
					/* check if a eoe packet is ready to transmit */
					//eoeReplyPending = eoe_tx_ready(); /* add this to use initiative tx of ethernet packets */

					if (pdo_insize>0) {
						c_pdo_s <: pdo_insize;
						for (int i=0; i<pdo_insize; i++) {
							c_pdo_s <: (unsigned int)pdo_inbuf[i];
						}
						pdo_insize = 0;
					} else {
						c_pdo_s <: pdo_insize;
					}
				}
				break;

			default:
				break;
			}

			/* FIXME Check for potential race conditions between this internal package and channel based communication! */
			if (pending_mailbox != 1 && foeReplyPending == 1) {
				out_size = (foe_get_reply(out_buffer)*2); // FIXME foe_get_reply() returns the number of words
				out_type = FOE_PACKET;
				pending_mailbox = 1;
				foeReplyPending = 0;
			}

			if (pending_mailbox != 1 && eoeReplyPending == 1) {
				out_size = (eoe_get_reply(out_buffer)*2); // FIXME eoe_get_reply() returns the number of words
				out_type = EOE_PACKET;
				pending_mailbox = 1;
				eoeReplyPending = eoe_check_chunks(); /* Check if there are still chunks to transfere */
				//printstr("[DEBUG EoE] more packets? eoeReplyPending="); printintln(eoeReplyPending);
			}

			if (pending_mailbox != 1 && coeReplyPending == 1) {
				out_size = (uint16_t)coe_get_reply((out_buffer, unsigned char[]));
				out_type = COE_PACKET;
				pending_mailbox = 1;
				coeReplyPending = 0; /* FIXME check for further segments */
				//printstr("[DEBUG CoE] more packets? coeReplyPending="); printintln(coeReplyPending);
			}
		}
	}
	EC_CS_UNSET();
}
