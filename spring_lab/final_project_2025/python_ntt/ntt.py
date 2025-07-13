# Input: 16 bit 1024 point input, less than 12289 => montogomery form, normal order, hex
# Ex: {16bit 0, data} => 0x0000(data)

# Twiddle : montogomery form, normal order
# Output: montogomery form, bit reverse order

import numpy as np
import os
import random
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
# Rinv = 12288  # R^-1 mod Q

# NTT
NTT_DIR = "ntt/"

NTT_IN_FILE = os.path.join(NTT_DIR, "ntt_in.txt")
NTT_IN_HEX_FILE = os.path.join(NTT_DIR, "ntt_in_hex.txt")
NTT_IN_M_FILE = os.path.join(NTT_DIR, "ntt_in_m.txt")
NTT_IN_HEX_M_FILE = os.path.join(NTT_DIR, "ntt_in_hex_m.txt")

NTT_OUT_FILE = os.path.join(NTT_DIR, "ntt_out.txt")
NTT_OUT_HEX_FILE = os.path.join(NTT_DIR, "ntt_out_hex.txt")
NTT_OUT_M_FILE = os.path.join(NTT_DIR, "ntt_out_m.txt")
NTT_OUT_HEX_M_FILE = os.path.join(NTT_DIR, "ntt_out_hex_m.txt")

NTT_TWIDDLE_FILE = os.path.join(NTT_DIR, "ntt_coef.txt")
NTT_TWIDDLE_HEX_M_FILE = os.path.join(NTT_DIR, "ntt_coef_hex_m.txt")

# INTT
INTT_DIR = "intt/"

INTT_IN_FILE = os.path.join(INTT_DIR, "intt_in.txt")
INTT_IN_HEX_FILE = os.path.join(INTT_DIR, "intt_in_hex.txt")
INTT_IN_M_FILE = os.path.join(INTT_DIR, "intt_in_m.txt")
INTT_IN_HEX_M_FILE = os.path.join(INTT_DIR, "intt_in_hex_m.txt")

INTT_OUT_FILE = os.path.join(INTT_DIR, "intt_out.txt")
INTT_OUT_HEX_FILE = os.path.join(INTT_DIR, "intt_out_hex.txt")
INTT_OUT_M_FILE = os.path.join(INTT_DIR, "intt_out_m.txt")
INTT_OUT_HEX_M_FILE = os.path.join(INTT_DIR, "intt_out_hex_m.txt")

INTT_TWIDDLE_FILE = os.path.join(INTT_DIR, "intt_coef.txt")
INTT_TWIDDLE_HEX_M_FILE = os.path.join(INTT_DIR, "intt_coef_hex_m.txt")


def bit_reverse(a: list[int], n: int = N) -> list[int]:
    """Bit-reverse the input array."""
    bits = n.bit_length() - 1
    return [a[int(f"{i:0{bits}b}"[::-1], 2)] for i in range(n)]


def ntt(a: list[int], twiddle: list[int], inverse: bool = False) -> list[int]:
    n = len(a)

    # Bit-reverse the input
    a = bit_reverse(a, n)

    # Perform the NTT
    for s in range(1, n.bit_length()):
        m = 1 << s
        w_m = twiddle[n // m] if not inverse else twiddle[n - n // m]
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
    k = k % n
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
    assert c == golden, "NTT multiplication did not match direct multiplication."

    return True


def gen_ntt(a: list[int], n: int = N) -> None:
    os.makedirs(NTT_DIR, exist_ok=True)
    os.makedirs(INTT_DIR, exist_ok=True)

    twiddle: list[int] = [get_twiddle(i, n) for i in range(n)]
    twiddle_inv: list[int] = [get_twiddle(-i, n) for i in range(n)]

    a_ntt: list[int] = ntt(a, twiddle)
    a_ro: list[int] = bit_reverse(a, n)
    a_ntt_ro: list[int] = bit_reverse(a_ntt, n)

    twiddle_m: list[int] = montgomery_form(twiddle)
    twiddle_inv_m: list[int] = montgomery_form(twiddle_inv)
    a_m: list[int] = montgomery_form(a)
    a_ro_m: list[int] = montgomery_form(a_ro)
    a_ntt_m: list[int] = montgomery_form(a_ntt)
    a_ntt_ro_m: list[int] = montgomery_form(a_ntt_ro)

    ### NTT
    # Input in normal order
    with open(NTT_IN_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a) + "\n")
    with open(NTT_IN_HEX_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a) + "\n")

    # Input in Montgomery form, normal order
    with open(NTT_IN_M_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a_m) + "\n")
    with open(NTT_IN_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a_m) + "\n")

    # Twiddle factors
    with open(NTT_TWIDDLE_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in twiddle) + "\n")
    with open(NTT_TWIDDLE_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in twiddle_m) + "\n")

    # NTT in bit-reverse order
    with open(NTT_OUT_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a_ntt_ro) + "\n")
    with open(NTT_OUT_HEX_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a_ntt_ro) + "\n")

    # NTT in Montgomery form, bit-reverse order
    with open(NTT_OUT_M_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a_ntt_ro_m) + "\n")
    with open(NTT_OUT_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a_ntt_ro_m) + "\n")

    ### INTT
    # NTT in normal order
    with open(INTT_IN_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a_ntt) + "\n")
    with open(INTT_IN_HEX_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a_ntt) + "\n")

    # NTT in Montgomery form, normal order
    with open(INTT_IN_M_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a_ntt_m) + "\n")
    with open(INTT_IN_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a_ntt_m) + "\n")

    # Twiddle factors for INTT
    with open(INTT_TWIDDLE_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in twiddle_inv) + "\n")
    # Twiddle factors in Montgomery form for INTT
    with open(INTT_TWIDDLE_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in twiddle_inv_m) + "\n")

    # Input in bit-reverse order
    with open(INTT_OUT_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a_ro) + "\n")
    with open(INTT_OUT_HEX_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a_ro) + "\n")

    # Input in Montgomery form, bit-reverse order
    # with open(INTT_OUT_M_FILE, "w") as f:
    #     f.write("\n".join(f"{x}" for x in a_ro_m) + "\n")
    # with open(INTT_OUT_HEX_M_FILE, "w") as f:
    #     f.write("\n".join(f"{x:08x}" for x in a_ro_m) + "\n")
    with open(INTT_OUT_M_FILE, "w") as f:
        f.write("\n".join(f"{x}" for x in a_ro) + "\n")
    with open(INTT_OUT_HEX_M_FILE, "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a_ro) + "\n")

    Ninv: int = pow(n, -1, Q)  # N^-1 mod Q
    a_ntt_ro_divn_m: list[int] = [
        (x * Ninv) % Q for x in a_ntt_ro_m
    ]  # Divide by N in Montgomery form
    with open("ntt_out_div_n_hex_m.txt", "w") as f:
        f.write("\n".join(f"{x:08x}" for x in a_ntt_ro_divn_m) + "\n")
    assert [(x * n) % Q for x in a_ntt_ro_divn_m] == a_ntt_ro_m, "NTT output in Montgomery form did not match NTT output divided by N."

    # Verify if (a_m, and a_ntt_ro_m) match the NTT result by matrix multiplication
    Rinv: int = pow(R, -1, Q)  # R^-1 mod Q
    twiddle_m_matrix: np.array = np.array(
        [montgomery_form([twiddle[i * j % n] for j in range(n)]) for i in range(n)]
    )
    a_m_v: np.array = np.array(a_m).reshape(-1, 1)
    a_ntt_m_v: np.array = np.array(bit_reverse(a_ntt_ro_m, n)).reshape(-1, 1)
    computed_ntt_m_v: np.array = (twiddle_m_matrix @ a_m_v) % Q * Rinv % Q
    assert np.all(
        computed_ntt_m_v.flatten() == a_ntt_m_v.flatten()
    ), "Twiddle matrix multiplication did not match NTT result for a in Montgomery form."

    # Verify if (a_ntt_m, a_ro_m) match the INTT result by matrix multiplication
    Ninv: int = pow(n, -1, Q)  # N^-1 mod Q
    Ninv_m: int = (Ninv * R) % Q  # Ninv Montgomery form
    twiddle_inv_m_matrix: np.array = np.array(
        [montgomery_form([twiddle[-i * j % n] for j in range(n)]) for i in range(n)]
    )
    a_ntt_m_v: np.array = np.array(a_ntt_m).reshape(-1, 1)
    a_m_v: np.array = np.array(bit_reverse(a_ro_m, n)).reshape(-1, 1)
    computed_intt_m_v: np.array = (
        (twiddle_inv_m_matrix @ a_ntt_m_v) % Q * Rinv % Q * Ninv_m % Q * Rinv % Q
    )
    assert np.all(
        computed_intt_m_v.flatten() == a_m_v.flatten()
    ), "Twiddle matrix inverse multiplication did not match INTT result for a in Montgomery form."


def main():
    # Generate a random input of size n.
    n: int = N
    a: list[int] = gen_input(n)

    gen_ntt(a, n)

    factors: list[int] = []
    for i in range(1, Q):
        if (Q - 1) % i == 0:
            factors.append(i)

    g: list[int] = []
    for x in range(1, Q):
        for f in factors:
            if pow(x, f, Q) == 1:
                if f == Q - 1:
                    g.append(x)
                break
    with open("g.txt", "w") as f:
        f.write("\n".join(f"{x}" for x in g) + "\n")

    # Verify the NTT
    for i in tqdm.tqdm(range(10), desc="Verifying NTT"):
        assert verify_ntt(), f"Verification failed at index {i}."


if __name__ == "__main__":
    main()
