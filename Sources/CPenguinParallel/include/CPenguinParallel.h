#ifndef _C_Penguin_Parallel_H_
#define _C_Penguin_Parallel_H_

#include <stdatomic.h>

enum CWorkItemState {
  kPre, kOngoing, kFinished
};

struct CWorkItem {
  atomic_char state;
};

void initializeItem(struct CWorkItem* item) {
	item->state = kPre;
}

_Bool tryTakeItem(struct CWorkItem* item) {
	char expected = kPre;
	return atomic_compare_exchange_strong(&item->state, &expected, kOngoing);
}

_Bool tryConsumeItem(struct CWorkItem* item) {
	char result = atomic_load_explicit(&item->state, memory_order_acquire);
	return result == kFinished;
}

void markItemFinished(struct CWorkItem* item) {
	atomic_store_explicit(&item->state, kFinished, memory_order_release);
}


#endif // #define _C_Penguin_Parallel_H_
