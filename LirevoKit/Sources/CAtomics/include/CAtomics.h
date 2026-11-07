// SPDX-License-Identifier: GPL-3.0-or-later
//
// Kilitsiz tamsayı atomikleri (C11 stdatomic). Gerçek zamanlı ses iş parçacığında
// güvenle kullanılabilir: bellek ayırmaz, kilit almaz.
// Swift tarafında `swift-atomics` (üçüncü taraf) ve `Synchronization.Atomic`
// (macOS 15+) yerine kullanılır. Bkz. docs/trd.md §5.

#ifndef CATOMICS_H
#define CATOMICS_H

#include <stdatomic.h>
#include <stdint.h>

typedef struct {
    _Atomic(uint64_t) value;
} lirevo_atomic_u64;

static inline void lirevo_atomic_u64_init(lirevo_atomic_u64 *a, uint64_t v) {
    atomic_init(&a->value, v);
}

static inline uint64_t lirevo_atomic_u64_load_acquire(lirevo_atomic_u64 *a) {
    return atomic_load_explicit(&a->value, memory_order_acquire);
}

static inline uint64_t lirevo_atomic_u64_load_relaxed(lirevo_atomic_u64 *a) {
    return atomic_load_explicit(&a->value, memory_order_relaxed);
}

static inline void lirevo_atomic_u64_store_release(lirevo_atomic_u64 *a, uint64_t v) {
    atomic_store_explicit(&a->value, v, memory_order_release);
}

/// Eski değeri döndürür.
static inline uint64_t lirevo_atomic_u64_fetch_add_acq_rel(lirevo_atomic_u64 *a, uint64_t delta) {
    return atomic_fetch_add_explicit(&a->value, delta, memory_order_acq_rel);
}

/// Başarılıysa 1 döner; başarısızsa `expected` güncel değerle doldurulur.
static inline int lirevo_atomic_u64_compare_exchange_acq_rel(lirevo_atomic_u64 *a, uint64_t *expected, uint64_t desired) {
    return atomic_compare_exchange_strong_explicit(&a->value, expected, desired,
                                                   memory_order_acq_rel, memory_order_acquire);
}

#endif /* CATOMICS_H */
