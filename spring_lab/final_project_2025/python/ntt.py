# Input: 16 bit 1024 point input, less than 12289 => montogomery form, normal order, hex
# Ex: {16bit 0, data} => 0x0000(data)

# Twiddle : montogomery form, normal order
# Output: montogomery form, bit reverse order

import random
import numpy as np
import tqdm

N = 1024
Q = 12 * 1024 + 1  # 12289
# order(G) = 12288
G = 1148
# Ninv = pow(N, -1, Q)  # N^-1 mod Q
# Q0I = 12287

# q0i = -1/q mod 2^16

# For Montgomery
R = 2**16  # R = 65536
Rinv = 12288  # R^-1 mod Q

IN_FILE = "ntt_in.txt"
IN_HEX_FILE = "ntt_in_hex.txt"
IN_M_FILE = "ntt_in_m.txt"
IN_HEX_M_FILE = "ntt_in_hex_m.txt"

TWIDDLE_FILE = "ntt_coef.txt"
TWIDDLE_HEX_M_FILE = "ntt_coef_hex_m.txt"

OUT_FILE = "ntt_out.txt"
OUT_HEX_FILE = "ntt_out_hex.txt"
OUT_M_FILE = "ntt_out_m.txt"
OUT_HEX_M_FILE = "ntt_out_hex_m.txt"


def bit_reverse(a: int, n: int) -> int:
    """Returns the bit-reversed version of x with n bits."""
    x: list[int] = [
        a[int("{:0{width}b}".format(i, width=n.bit_length() - 1)[::-1], 2)]
        for i in range(n)
    ]
    return x

def ntt(a: list[int], twiddle: list[int], inverse: bool = False) -> list[int]:
    n = len(a)

    # Bit-reverse the input
    a = bit_reverse(a, n)

    # Perform the NTT
    for s in range(1, n.bit_length()):
        m = 1 << s
        w_m = twiddle[n // m] if not inverse else pow(twiddle[n // m], -1, Q)
        for k in range(0, n, m):
            w = 1
            for j in range(m // 2):
                u = a[k + j]
                v = (a[k + j + m // 2] * w) % Q
                a[k + j] = (u + v) % Q
                a[k + j + m // 2] = (u - v) % Q
                w = (w * w_m) % Q

    if inverse:
        ninv: int = pow(n, -1, Q)  # N^-1 mod Q
        a = [(x * ninv) % Q for x in a]

    return a


def gen_input(n: int = N) -> list[int]:
    """Generates a random input for the NTT algorithm and writes it to files."""
    return [random.randint(0, Q - 1) for _ in range(n)]


def get_twiddle(k: int = 1, n: int = N) -> int:
    """Returns w^k_n = G^(k * (Q - 1) / n) mod Q."""
    assert (Q - 1) % n == 0, "Q-1 must be divisible by N."
    k = (k % n + n) % n
    return pow(G, (Q - 1) * k // n, Q)


def montgomery_form(x: list[int]) -> list[int]:
    """Converts a list of integers to Montgomery form."""
    return [(xi * R) % Q for xi in x]


def verify_ntt() -> bool:
    n = N
    a: list[int] = gen_input(n)
    b: list[int] = gen_input(n)
    twiddle: list[int] = [get_twiddle(i, n) for i in range(n)]

    ntt_a: list[int] = ntt(a, twiddle)
    ntt_b: list[int] = ntt(b, twiddle)

    assert a == ntt(
        ntt_a, twiddle, inverse=True
    ), "NTT forward and inverse did not match for a."
    assert b == ntt(
        ntt_b, twiddle, inverse=True
    ), "NTT forward and inverse did not match for b."

    ntt_c: list[int] = [x * y % Q for x, y in zip(ntt_a, ntt_b)]
    c: list[int] = ntt(ntt_c, twiddle, inverse=True)

    twiddle_matrix: np.array = np.array(
        [[get_twiddle(i * j, n) for j in range(n)] for i in range(n)]
    )
    # Verify that twiddle_matrix * a = ntt_a
    a_vector = np.array(a).reshape(-1, 1)
    ntt_a_vector = np.array(ntt_a).reshape(-1, 1)
    computed_ntt_a = (twiddle_matrix @ a_vector) % Q
    assert np.all(
        computed_ntt_a.flatten() == ntt_a_vector.flatten()
    ), "Twiddle matrix multiplication did not match NTT result for a."
    b_vector = np.array(b).reshape(-1, 1)
    ntt_b_vector = np.array(ntt_b).reshape(-1, 1)
    computed_ntt_b = (twiddle_matrix @ b_vector) % Q
    assert np.all(
        computed_ntt_b.flatten() == ntt_b_vector.flatten()
    ), "Twiddle matrix multiplication did not match NTT result for b."

    twiddle_matrix_inv: np.array = (
        np.array([[get_twiddle(-i * j, n) for j in range(n)] for i in range(n)])
        * pow(n, -1, Q)
        % Q
    )
    ntt_c_vector = ntt_a_vector * ntt_b_vector % Q
    computed_c = (twiddle_matrix_inv @ ntt_c_vector) % Q
    c_vector = np.array(c).reshape(-1, 1)
    assert np.all(
        computed_c.flatten() == c_vector.flatten()
    ), "Twiddle matrix inverse multiplication did not match NTT result for c."

    assert np.all(
        np.eye(n) == (twiddle_matrix @ twiddle_matrix_inv) % Q
    ), "Twiddle matrix and its inverse did not yield identity matrix."

    golden: list[int] = [0] * n
    for k in range(n):
        for i in range(n):
            golden[k] = (golden[k] + a[i] * b[(k - i) % n]) % Q
    return c == golden


def main():
    # Generate a random input of size n.
    n: int = N
    a: list[int] = gen_input(n)
    with open(IN_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a) + "\n")
    with open(IN_HEX_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a) + "\n")

    # Input in Montgomery form
    am = montgomery_form(a)
    with open(IN_M_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in am) + "\n")
    with open(IN_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in am) + "\n")

    # Twiddle factors
    twiddle = [get_twiddle(i, n) for i in range(n)]
    with open(TWIDDLE_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in twiddle) + "\n")

    # Twiddle factors in Montgomery form
    twiddle_m = montgomery_form(twiddle)
    with open(TWIDDLE_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in twiddle_m) + "\n")

    # NTT in bit-reverse order
    ntt_a: list[int] = bit_reverse(ntt(a, twiddle), n)
    with open(OUT_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in ntt_a) + "\n")
    with open(OUT_HEX_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in ntt_a) + "\n")

    # NTT in Montgomery form
    ntt_am: list[int] = montgomery_form(ntt_a)
    with open(OUT_M_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in ntt_am) + "\n")
    with open(OUT_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in ntt_am) + "\n")

    # Verify the NTT
    for i in tqdm.tqdm(range(10), desc="Verifying NTT"):
        assert verify_ntt(), f"Verification failed at index {i}."


if __name__ == "__main__":
    main()
