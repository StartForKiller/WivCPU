#ifndef _PROC_SCHEDULER_H
#define _PROC_SCHEDULER_H

#include <kernel/isr.h>

typedef struct {
    isr_context_t *context;
} process_t;

#endif