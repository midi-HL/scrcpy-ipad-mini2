/**
 * util.h
 *
 * Utility functions.
 * This is a placeholder for the official scrcpy util module.
 */

#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// Thread utilities
typedef void* (*thread_func_t)(void*);

// Create thread
int util_thread_create(void **thread, thread_func_t func, void *arg);

// Join thread
int util_thread_join(void *thread);

// Mutex
typedef struct util_mutex util_mutex_t;

util_mutex_t* util_mutex_create(void);
void util_mutex_destroy(util_mutex_t *mutex);
void util_mutex_lock(util_mutex_t *mutex);
void util_mutex_unlock(util_mutex_t *mutex);

// Condition variable
typedef struct util_cond util_cond_t;

util_cond_t* util_cond_create(void);
void util_cond_destroy(util_cond_t *cond);
void util_cond_signal(util_cond_t *cond);
void util_cond_wait(util_cond_t *cond, util_mutex_t *mutex);

// Queue
typedef struct util_queue util_queue_t;

util_queue_t* util_queue_create(int capacity);
void util_queue_destroy(util_queue_t *queue);
int util_queue_push(util_queue_t *queue, void *data);
void* util_queue_pop(util_queue_t *queue);
int util_queue_size(util_queue_t *queue);

// String utilities
char* util_strdup(const char *str);
bool util_str_starts_with(const char *str, const char *prefix);

// Network utilities
int util_socket_connect(const char *host, int port);
int util_socket_read(int socket, void *buf, size_t size);
int util_socket_write(int socket, const void *buf, size_t size);
void util_socket_close(int socket);

#endif // UTIL_H
