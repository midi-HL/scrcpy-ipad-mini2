/**
 * scrcpy_core.c
 *
 * Scrcpy core implementation for iOS.
 * Manages connection to Android device and video/audio streaming.
 */

#include "scrcpy_core.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>

// Scrcpy state
static struct {
    int state;
    int socket;
    char *serial;
    scrcpy_options_t options;

    scrcpy_video_callback video_cb;
    scrcpy_audio_callback audio_cb;
    scrcpy_state_callback state_cb;
    void *user_data;

    pthread_t video_thread;
    pthread_t control_thread;
    volatile int running;

    int device_width;
    int device_height;
} scrcpy_state;

// Send message to server
static int send_message(int sock, const void *data, size_t size) {
    const uint8_t *ptr = (const uint8_t *)data;
    size_t sent = 0;

    while (sent < size) {
        ssize_t n = send(sock, ptr + sent, size - sent, 0);
        if (n <= 0) return -1;
        sent += n;
    }

    return 0;
}

// Receive message from server
static int recv_message(int sock, void *data, size_t size) {
    uint8_t *ptr = (uint8_t *)data;
    size_t received = 0;

    while (received < size) {
        ssize_t n = recv(sock, ptr + received, size - received, MSG_WAITALL);
        if (n <= 0) return -1;
        received += n;
    }

    return 0;
}

// Video receive thread
static void* video_receive_thread(void *arg) {
    (void)arg;

    printf("[scrcpy] Video thread started\n");

    while (scrcpy_state.running) {
        // Receive packet header (12 bytes: 4 size + 8 pts)
        uint8_t header[12];
        if (recv_message(scrcpy_state.socket, header, sizeof(header)) < 0) {
            if (scrcpy_state.running) {
                printf("[scrcpy] Video connection lost\n");
                scrcpy_state.state = SCRCPY_STATE_ERROR;
                if (scrcpy_state.state_cb) {
                    scrcpy_state.state_cb(SCRCPY_STATE_ERROR, scrcpy_state.user_data);
                }
            }
            break;
        }

        // Parse header
        uint32_t packet_size = ntohl(*(uint32_t *)header);
        uint64_t pts = ((uint64_t)ntohl(*(uint32_t *)(header + 4)) << 32) |
                       ntohl(*(uint32_t *)(header + 8));

        // Validate size
        if (packet_size > 10 * 1024 * 1024) {
            printf("[scrcpy] Invalid packet size: %u\n", packet_size);
            break;
        }

        // Allocate buffer
        uint8_t *data = (uint8_t *)malloc(packet_size);
        if (!data) {
            printf("[scrcpy] Memory allocation failed\n");
            break;
        }

        // Receive data
        if (recv_message(scrcpy_state.socket, data, packet_size) < 0) {
            free(data);
            break;
        }

        // Check if keyframe
        int keyframe = 0;
        if (packet_size > 0) {
            uint8_t nalu_type = data[0] & 0x1F;
            if (nalu_type == 5) { // IDR
                keyframe = 1;

                // Parse SPS to get resolution
                if (packet_size > 4) {
                    // Simple SPS parsing to extract resolution
                    // This is a simplified version
                    printf("[scrcpy] Keyframe received, size=%u\n", packet_size);
                }
            }
        }

        // Create packet
        scrcpy_video_packet_t packet;
        packet.pts = pts;
        packet.size = packet_size;
        packet.data = data;
        packet.keyframe = keyframe;

        // Call callback
        if (scrcpy_state.video_cb) {
            scrcpy_state.video_cb(&packet, scrcpy_state.user_data);
        }

        free(data);
    }

    printf("[scrcpy] Video thread exiting\n");
    return NULL;
}

// Initialize scrcpy
int scrcpy_init(void) {
    memset(&scrcpy_state, 0, sizeof(scrcpy_state));
    scrcpy_state.state = SCRCPY_STATE_DISCONNECTED;
    scrcpy_state.socket = -1;
    return 0;
}

// Start scrcpy session
int scrcpy_start(const char *serial, const scrcpy_options_t *options,
                 scrcpy_video_callback video_cb,
                 scrcpy_audio_callback audio_cb,
                 scrcpy_state_callback state_cb,
                 void *user_data) {
    if (scrcpy_state.state != SCRCPY_STATE_DISCONNECTED) {
        scrcpy_stop();
    }

    printf("[scrcpy] Starting session for %s\n", serial);

    // Copy serial
    scrcpy_state.serial = strdup(serial);
    if (!scrcpy_state.serial) return -1;

    // Copy options
    if (options) {
        scrcpy_state.options = *options;
    } else {
        scrcpy_state.options.max_size = SCRCPY_DEFAULT_MAX_SIZE;
        scrcpy_state.options.bit_rate = SCRCPY_DEFAULT_BIT_RATE;
        scrcpy_state.options.max_fps = SCRCPY_DEFAULT_MAX_FPS;
    }

    // Set callbacks
    scrcpy_state.video_cb = video_cb;
    scrcpy_state.audio_cb = audio_cb;
    scrcpy_state.state_cb = state_cb;
    scrcpy_state.user_data = user_data;

    // Set state to connecting
    scrcpy_state.state = SCRCPY_STATE_CONNECTING;
    if (scrcpy_state.state_cb) {
        scrcpy_state.state_cb(SCRCPY_STATE_CONNECTING, scrcpy_state.user_data);
    }

    // Parse serial (host:port)
    char host[256];
    int port = 5555;
    sscanf(serial, "%255[^:]:%d", host, &port);

    // Create socket
    scrcpy_state.socket = socket(AF_INET, SOCK_STREAM, 0);
    if (scrcpy_state.socket < 0) {
        printf("[scrcpy] Failed to create socket\n");
        scrcpy_state.state = SCRCPY_STATE_ERROR;
        return -1;
    }

    // Connect
    struct hostent *server = gethostbyname(host);
    if (!server) {
        printf("[scrcpy] Failed to resolve host: %s\n", host);
        close(scrcpy_state.socket);
        scrcpy_state.socket = -1;
        scrcpy_state.state = SCRCPY_STATE_ERROR;
        return -1;
    }

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    memcpy(&server_addr.sin_addr.s_addr, server->h_addr, server->h_length);

    if (connect(scrcpy_state.socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        printf("[scrcpy] Failed to connect to %s:%d\n", host, port);
        close(scrcpy_state.socket);
        scrcpy_state.socket = -1;
        scrcpy_state.state = SCRCPY_STATE_ERROR;
        return -1;
    }

    printf("[scrcpy] Connected to %s:%d\n", host, port);

    // Send device name
    uint32_t device_name_len = strlen(scrcpy_state.serial);
    send_message(scrcpy_state.socket, &device_name_len, sizeof(device_name_len));
    send_message(scrcpy_state.socket, scrcpy_state.serial, device_name_len);

    // Send options
    uint32_t opts[4];
    opts[0] = htonl(scrcpy_state.options.max_size);
    opts[1] = htonl(scrcpy_state.options.bit_rate);
    opts[2] = htonl(scrcpy_state.options.max_fps);
    opts[3] = htonl(scrcpy_state.options.lock_video_orientation);
    send_message(scrcpy_state.socket, opts, sizeof(opts));

    // Set state to connected
    scrcpy_state.state = SCRCPY_STATE_CONNECTED;
    scrcpy_state.running = 1;

    if (scrcpy_state.state_cb) {
        scrcpy_state.state_cb(SCRCPY_STATE_CONNECTED, scrcpy_state.user_data);
    }

    // Start video thread
    int result = pthread_create(&scrcpy_state.video_thread, NULL, video_receive_thread, NULL);
    if (result != 0) {
        printf("[scrcpy] Failed to create video thread\n");
        scrcpy_stop();
        return -1;
    }

    scrcpy_state.state = SCRCPY_STATE_STREAMING;
    if (scrcpy_state.state_cb) {
        scrcpy_state.state_cb(SCRCPY_STATE_STREAMING, scrcpy_state.user_data);
    }

    printf("[scrcpy] Streaming started\n");
    return 0;
}

// Stop scrcpy session
void scrcpy_stop(void) {
    if (scrcpy_state.state == SCRCPY_STATE_DISCONNECTED) return;

    printf("[scrcpy] Stopping session\n");

    scrcpy_state.running = 0;

    // Wait for video thread
    if (scrcpy_state.video_thread) {
        pthread_join(scrcpy_state.video_thread, NULL);
        scrcpy_state.video_thread = 0;
    }

    // Close socket
    if (scrcpy_state.socket >= 0) {
        close(scrcpy_state.socket);
        scrcpy_state.socket = -1;
    }

    // Free serial
    if (scrcpy_state.serial) {
        free(scrcpy_state.serial);
        scrcpy_state.serial = NULL;
    }

    scrcpy_state.state = SCRCPY_STATE_DISCONNECTED;

    if (scrcpy_state.state_cb) {
        scrcpy_state.state_cb(SCRCPY_STATE_DISCONNECTED, scrcpy_state.user_data);
    }

    printf("[scrcpy] Session stopped\n");
}

// Get current state
int scrcpy_get_state(void) {
    return scrcpy_state.state;
}

// Send control message
int scrcpy_send_key(int keycode, int action) {
    if (scrcpy_state.state != SCRCPY_STATE_STREAMING) return -1;

    uint8_t msg[9];
    msg[0] = 0; // TYPE_KEYCODE
    uint32_t act = htonl(action);
    uint32_t key = htonl(keycode);
    memcpy(msg + 1, &act, 4);
    memcpy(msg + 5, &key, 4);

    return send_message(scrcpy_state.socket, msg, sizeof(msg));
}

int scrcpy_send_touch(int action, int x, int y, int width, int height) {
    if (scrcpy_state.state != SCRCPY_STATE_STREAMING) return -1;

    uint8_t msg[14];
    msg[0] = 2; // TYPE_MOUSE
    uint32_t x_val = htonl(x);
    uint32_t y_val = htonl(y);
    uint16_t w_val = htons(width);
    uint16_t h_val = htons(height);
    uint8_t buttons = (action == 0) ? 1 : 0; // LEFT button

    memcpy(msg + 1, &x_val, 4);
    memcpy(msg + 5, &y_val, 4);
    memcpy(msg + 9, &w_val, 2);
    memcpy(msg + 11, &h_val, 2);
    msg[13] = buttons;

    return send_message(scrcpy_state.socket, msg, sizeof(msg));
}

int scrcpy_send_text(const char *text) {
    if (scrcpy_state.state != SCRCPY_STATE_STREAMING) return -1;

    size_t len = strlen(text);
    uint8_t *msg = (uint8_t *)malloc(5 + len);
    if (!msg) return -1;

    msg[0] = 1; // TYPE_TEXT
    uint32_t text_len = htonl(len);
    memcpy(msg + 1, &text_len, 4);
    memcpy(msg + 5, text, len);

    int result = send_message(scrcpy_state.socket, msg, 5 + len);
    free(msg);
    return result;
}

int scrcpy_send_scroll(int x, int y) {
    if (scrcpy_state.state != SCRCPY_STATE_STREAMING) return -1;

    uint8_t msg[9];
    msg[0] = 3; // TYPE_SCROLL
    int32_t x_val = htonl(x);
    int32_t y_val = htonl(y);
    memcpy(msg + 1, &x_val, 4);
    memcpy(msg + 5, &y_val, 4);

    return send_message(scrcpy_state.socket, msg, sizeof(msg));
}

// Get device info
int scrcpy_get_device_size(int *width, int *height) {
    if (width) *width = scrcpy_state.device_width;
    if (height) *height = scrcpy_state.device_height;
    return 0;
}

// Set options
void scrcpy_set_max_size(int max_size) {
    scrcpy_state.options.max_size = max_size;
}

void scrcpy_set_bit_rate(int bit_rate) {
    scrcpy_state.options.bit_rate = bit_rate;
}

void scrcpy_set_max_fps(int max_fps) {
    scrcpy_state.options.max_fps = max_fps;
}
