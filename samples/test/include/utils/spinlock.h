#ifndef _UTILS_SPINLOCK_H
#define _UTILS_SPINLOCK_H

#include <utils/utils.h>

typedef struct {
	volatile uint32_t lock;
} spinlock_t;

#define SPINLOCK_UNLOCKED	{ 0 }
#define spinlock_locked(x)	(READ_ONCE((x)->lock) != 0)

static inline void spinlock_unlock(spinlock_t *lock) {
    asm volatile("amoswap.w.rl x0, x0, %0" :
                    "=A"(lock->lock) ::
                    "memory");
}

static inline int spinlock_trylock(spinlock_t *lock) {
    int tmp = 1, busy;
    asm volatile("amoswap.w.aq %0, %2, %1" :
                    "=r"(busy), "+A"(lock->lock) :
                    "r"(tmp) :
                    "memory");
    return !busy;
}

static inline void spinlock_lock(spinlock_t *lock) {
    while(1) {
        if(spinlock_locked(lock)) continue;
        if(spinlock_trylock(lock)) break;
    }
}

#endif