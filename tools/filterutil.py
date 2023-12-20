class FpFilter:
    def __init__(self, b, a, b_after_dot, a_after_dot):
        print(b)
        print(a)

        self.b = [int(round(x * 2 ** b_after_dot)) for x in b]
        self.a = [int(round(x * 2 ** a_after_dot)) for x in a]
        self.b_after_dot = b_after_dot
        self.a_after_dot = a_after_dot

        print(f"B {self.b}")
        print(f"A {self.a}")

        self.rs = [int(0)] * 8
        self.ls = [int(0)] * 8

        self.rs_total_or = [int(0)] * 8
        self.ls_total_or = [int(0)] * 8
        self.rounding = True

    def print_bit_usage(self):
        print(f"ls usage {[bin(x) for x in self.ls_total_or]}")
        print(f"ls usage {[x.bit_length() for x in self.ls_total_or]}")
        print(f"rs usage {[bin(x) for x in self.rs_total_or]}")
        print(f"rs usage {[x.bit_length() for x in self.rs_total_or]}")

    def filter_list(self, list):
        return [self.filter(int(x)) for x in list]

    def reduce(self, value, shift):
        if shift == 0:
            return int(value)

        if self.rounding:
            return (int(value) + (1 << (shift - 1))) >> shift
        else:
            return (int(value)) >> shift

    def filter(self, in_val):
        v = int(self.rs[0] + int(in_val))
        y = self.ls[0] + self.reduce(int(self.b[0]) * v, self.b_after_dot)
        for i in range(len(self.b) - 1):
            self.rs[i] = int(self.reduce(-self.a[i + 1] * v, self.a_after_dot) + self.rs[i + 1])
            self.ls[i] = int(self.reduce(self.b[i + 1] * v, self.b_after_dot) + self.ls[i + 1])

            if self.rs[i] >= 0:
                self.rs_total_or[i] |= self.rs[i]
            else:
                self.rs_total_or[i] |= -self.rs[i]

            if self.ls[i] >= 0:
                self.ls_total_or[i] |= self.ls[i]
            else:
                self.ls_total_or[i] |= -self.ls[i]

        return y
