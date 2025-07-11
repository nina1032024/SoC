# Montgomery 乘法模擬 (以 Q = 12289，常見於 NTT 應用)

def mq_montymul(x: int, y: int) -> int:
    Q = 12289
    Q0I = 12287  # Q * Q0I ≡ -1 mod 2^16 (65536)，手動計算可得

    # 計算 z = x * y
    z = x * y
    # w 是用來抵消低16bit 的補償項
    w = ((z * Q0I) & 0xFFFF) * Q
    # 加總後右移16位，模擬除以 R=2^16
    z = (z + w) >> 16
    # 調整結果落在 [0, Q)
    z -= Q
    if z < 0:
        z += Q
    return z

def mq_montysqr(x: int) -> int:
    return mq_montymul(x, x)

# 將一般整數轉為 Montgomery 表示
def to_montgomery(x: int) -> int:
    R2 = 10952  # 預先計算的 R^2 mod Q
    return mq_montymul(x, R2)

# 測試：將一個 16bit 以內整數轉為 Montgomery 表示
if __name__ == "__main__":
    Q = 12289
    for x in [2732, 10799, 9845]:
        mont_x = to_montgomery(x)
        print(f"Input: {x:5d} -> Montgomery form: {mont_x:5d}")
