def compress_file(input_file, output_file):
    with open(input_file, 'rb') as f:
        input_bytes = f.read()

    compressed_bytes = bytearray()
    current_byte = 0
    bit_count = 0

    for bit in input_bytes:
        current_byte = (current_byte << 1) | bit
        bit_count += 1

        if bit_count == 8:
            compressed_bytes.append(current_byte)
            current_byte = 0
            bit_count = 0

    if bit_count > 0:
        compressed_bytes.append(current_byte << (8 - bit_count))

    with open(output_file, 'wb') as f:
        f.write(compressed_bytes)

if __name__ == "__main__":
    input_file = "level_1.bin"  # Replace with your input file
    output_file = "level_1.bin.c"  # Replace with your output file

    compress_file(input_file, output_file)
    print(f"Compressione completata. File compresso salvato come {output_file}")
