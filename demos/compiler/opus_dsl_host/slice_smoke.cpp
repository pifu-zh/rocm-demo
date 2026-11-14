#include "vendor/opus_host_slice.hpp"
#include <cstdio>
int main() {
    constexpr auto s = opus::make_index_seq<5>();
    static_assert(s.size() == 5);
    printf("slice host compile OK, seq size %d\n", (int)s.size());
    return 0;
}
