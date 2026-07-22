/**
 * demuxer.h
 *
 * Demuxer interface for parsing video stream packets.
 * This is a placeholder for the official scrcpy demuxer module.
 */

#ifndef DEMUXER_H
#define DEMUXER_H

#include <stdint.h>
#include <stddef.h>

// Demuxer packet types
#define DEMUXER_PACKET_TYPE_CONFIG    0
#define DEMUXER_PACKET_TYPE_DATA      1

// Demuxer packet structure
typedef struct demuxer_packet {
    int type;
    uint64_t pts;
    uint64_t dts;
    size_t size;
    uint8_t *data;
} demuxer_packet_t;

// Initialize demuxer
int demuxer_init(void);

// Parse packet from stream
int demuxer_parse_packet(const uint8_t *data, size_t size, demuxer_packet_t *packet);

// Free packet
void demuxer_packet_free(demuxer_packet_t *packet);

// Get SPS/PPS from config packet
int demuxer_get_sps_pps(const demuxer_packet_t *config,
                        const uint8_t **sps, size_t *sps_size,
                        const uint8_t **pps, size_t *pps_size);

#endif // DEMUXER_H
