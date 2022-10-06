#include <iostream>

template <unsigned N>
struct factorial {
  static constexpr unsigned value = N * factorial<N - 1>::value;
};

template <>
struct factorial<0> {
  static constexpr unsigned value = 1;
};

int main(int argc, char* argv[]) {
  std::cout << factorial<7>::value  << std::endl;

  return 0;
}

