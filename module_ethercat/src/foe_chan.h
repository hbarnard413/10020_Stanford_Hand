
/**
 * @file foe_chan.h
 */

#ifndef FOE_CHAN_H
#define FOE_CHAN_H

/* defines for file access over channel */

/**
 * FOE_FILE_OPEN
 * open specified file for reading, replies FOE_FILE_OK on success or FOE_FILE_ERROR on error.
 * After FOE_FILE_OPEN the filename must be transfered over the channel.
 */
#define FOE_FILE_OPEN      10

/**
 * FOE_FILE_CLOSE
 * Finish file access operation
 */
#define FOE_FILE_CLOSE     13

/**
 * FOE_FILE_READ
 * After the command the maximum size of the local buffer should be sent.
 * Then up to the maximum number of bytes are transfered.
 */
#define FOE_FILE_READ      11

/**
 * FOE_WRITE size data
 *** currently unsupported ***
 */
#define FOE_FILE_WRITE     12

/**
 * FOE_FILE_SEEK
 * Followed by 'pos' to
 * set filepointer to (absolute) position 'pos', the next read/write operation will start from there.
 * With FOE_FILE_SEEK 0 the file pointer is rewind to the beginning of the file.
 */
#define FOE_FILE_SEEK      14

/**
 * FOE_FILE_FREE
 * This command will erase the file (or files), so further file access is possible.
 */
#define FOE_FILE_FREE      15

/* replies to the caller */

/**
 * Reply to FOE_FILE_OPEN if file is found and accessible.
 */
#define FOE_FILE_ACK       20

/**
 * Reply if error occures.
 */
#define FOE_FILE_ERROR     21

/**
 * Indicator for data, followed by data count and the individual bytes.
 */
#define FOE_FILE_DATA      22

/**
 * Control command if file is transfered and processable.
 */
#define FOE_FILE_READY     30

#endif /* FOE_CHAN_H */
