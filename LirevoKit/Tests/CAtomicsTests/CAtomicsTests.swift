// SPDX-License-Identifier: GPL-3.0-or-later

import Testing
import CAtomics

@Suite struct CAtomicsTests {
    @Test func loadStoreAndFetchAdd() {
        var atomic = lirevo_atomic_u64()
        lirevo_atomic_u64_init(&atomic, 5)
        #expect(lirevo_atomic_u64_load_acquire(&atomic) == 5)
        lirevo_atomic_u64_store_release(&atomic, 10)
        #expect(lirevo_atomic_u64_fetch_add_acq_rel(&atomic, 3) == 10)
        #expect(lirevo_atomic_u64_load_relaxed(&atomic) == 13)
    }

    @Test func compareExchange() {
        var atomic = lirevo_atomic_u64()
        lirevo_atomic_u64_init(&atomic, 1)
        var expected: UInt64 = 2
        #expect(lirevo_atomic_u64_compare_exchange_acq_rel(&atomic, &expected, 7) == 0)
        #expect(expected == 1)
        #expect(lirevo_atomic_u64_compare_exchange_acq_rel(&atomic, &expected, 7) == 1)
        #expect(lirevo_atomic_u64_load_acquire(&atomic) == 7)
    }

    @Test func concurrentIncrementsAreNotLost() async {
        let box = UnsafeMutablePointer<lirevo_atomic_u64>.allocate(capacity: 1)
        defer { box.deallocate() }
        lirevo_atomic_u64_init(box, 0)
        let address = UInt(bitPattern: box)
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    let pointer = UnsafeMutablePointer<lirevo_atomic_u64>(bitPattern: address)!
                    for _ in 0..<10_000 { _ = lirevo_atomic_u64_fetch_add_acq_rel(pointer, 1) }
                }
            }
        }
        #expect(lirevo_atomic_u64_load_acquire(box) == 80_000)
    }
}
