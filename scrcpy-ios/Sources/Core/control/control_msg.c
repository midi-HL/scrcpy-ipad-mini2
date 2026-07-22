/**
 * control_msg.c
 *
 * Scrcpy control message implementation.
 * Sends input events to Android device via ADB socket.
 */

#include "control.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

// Message type constants (from scrcpy protocol)
#define TYPE_KEYCODE         0
#define TYPE_TEXT            1
#define TYPE_MOUSE           2
#define TYPE_SCROLL          3
#define TYPE_BACK_OR_HOME    4
#define TYPE_EXPAND_NOTIFICATION  5
#define TYPE_EXPAND_SETTINGS     6
#define TYPE_COLLAPSE_PANELS      7
#define TYPE_ROTATE_DEVICE        8

// Mouse button constants
#define MOUSE_BUTTON_LEFT    (1 << 0)
#define MOUSE_BUTTON_RIGHT   (1 << 1)
#define MOUSE_BUTTON_MIDDLE  (1 << 2)

// Touch action constants
#define TOUCH_ACTION_DOWN    0
#define TOUCH_ACTION_UP      1
#define TOUCH_ACTION_MOVE    2

// Write uint16 in big-endian
static void write_uint16(uint8_t *buf, uint16_t value) {
    buf[0] = (value >> 8) & 0xFF;
    buf[1] = value & 0xFF;
}

// Write uint32 in big-endian
static void write_uint32(uint8_t *buf, uint32_t value) {
    buf[0] = (value >> 24) & 0xFF;
    buf[1] = (value >> 16) & 0xFF;
    buf[2] = (value >> 8) & 0xFF;
    buf[3] = value & 0xFF;
}

// Write int32 in big-endian
static void write_int32(uint8_t *buf, int32_t value) {
    write_uint32(buf, (uint32_t)value);
}

// Send raw data
static int send_all(int socket, const uint8_t *data, size_t size) {
    size_t sent = 0;
    while (sent < size) {
        ssize_t n = send(socket, data + sent, size - sent, 0);
        if (n <= 0) return -1;
        sent += n;
    }
    return 0;
}

// Send control message
int control_send(int socket, const control_msg_t *msg) {
    uint8_t buf[256];
    size_t len = 0;

    switch (msg->type) {
        case TYPE_KEYCODE: {
            buf[0] = TYPE_KEYCODE;
            write_uint32(buf + 1, msg->key.action);
            write_uint32(buf + 5, msg->key.keycode);
            len = 9;
            break;
        }

        case TYPE_TEXT: {
            buf[0] = TYPE_TEXT;
            size_t text_len = strlen(msg->text.text);
            write_uint32(buf + 1, (uint32_t)text_len);
            memcpy(buf + 5, msg->text.text, text_len);
            len = 5 + text_len;
            break;
        }

        case TYPE_MOUSE: {
            buf[0] = TYPE_MOUSE;
            write_uint32(buf + 1, msg->mouse.x);
            write_uint32(buf + 5, msg->mouse.y);
            write_uint16(buf + 9, msg->mouse.width);
            write_uint16(buf + 11, msg->mouse.height);
            buf[13] = msg->mouse.buttons;
            len = 14;
            break;
        }

        case TYPE_SCROLL: {
            buf[0] = TYPE_SCROLL;
            write_int32(buf + 1, msg->scroll.x);
            write_int32(buf + 5, msg->scroll.y);
            len = 9;
            break;
        }

        case TYPE_BACK_OR_HOME: {
            buf[0] = TYPE_BACK_OR_HOME;
            len = 1;
            break;
        }

        default:
            return -1;
    }

    return send_all(socket, buf, len);
}

// Send keycode
int control_send_keycode(int socket, uint32_t keycode, uint32_t action) {
    control_msg_t msg;
    msg.type = TYPE_KEYCODE;
    msg.key.action = action;
    msg.key.keycode = keycode;
    return control_send(socket, &msg);
}

// Send touch event
int control_send_touch(int socket, int action, int x, int y, int width, int height) {
    control_msg_t msg;
    msg.type = TYPE_MOUSE;
    msg.mouse.x = x;
    msg.mouse.y = y;
    msg.mouse.width = width;
    msg.mouse.height = height;

    switch (action) {
        case TOUCH_ACTION_DOWN:
            msg.mouse.buttons = MOUSE_BUTTON_LEFT;
            break;
        case TOUCH_ACTION_UP:
            msg.mouse.buttons = 0;
            break;
        case TOUCH_ACTION_MOVE:
            msg.mouse.buttons = MOUSE_BUTTON_LEFT;
            break;
        default:
            msg.mouse.buttons = 0;
    }

    return control_send(socket, &msg);
}

// Send scroll
int control_send_scroll(int socket, int x, int y) {
    control_msg_t msg;
    msg.type = TYPE_SCROLL;
    msg.scroll.x = x;
    msg.scroll.y = y;
    return control_send(socket, &msg);
}

// Send text
int control_send_text(int socket, const char *text) {
    control_msg_t msg;
    msg.type = TYPE_TEXT;
    strncpy(msg.text.text, text, 300);
    msg.text.text[300] = '\0';
    return control_send(socket, &msg);
}

// Send back button
int control_send_back(int socket) {
    return control_send_keycode(socket, KEYCODE_BACK, 1);
}

// Send home button
int control_send_home(int socket) {
    return control_send_keycode(socket, KEYCODE_HOME, 1);
}

// Send power button
int control_send_power(int socket) {
    return control_send_keycode(socket, KEYCODE_POWER, 1);
}

// Send volume up
int control_send_volume_up(int socket) {
    return control_send_keycode(socket, KEYCODE_VOLUME_UP, 1);
}

// Send volume down
int control_send_volume_down(int socket) {
    return control_send_keycode(socket, KEYCODE_VOLUME_DOWN, 1);
}
