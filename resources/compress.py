def compress_hero_levels(input_file, output_file):
    # Apriamo il file di input in modalità lettura binaria
    with open(input_file, 'rb') as infile:
        # Apriamo il file di output in modalità scrittura binaria
        with open(output_file, 'wb') as outfile:
            # Leggiamo il contenuto del file di input
            data = infile.read()
            
            # Verifica che il numero di byte sia multiplo di 8
            if len(data) % 8 != 0:
                print("Il file di input non ha un numero di byte multiplo di 8")
                return
            
            # Processiamo ogni blocco di 8 byte
            for i in range(0, len(data), 8):
                # Prendiamo il blocco di 8 byte
                block = data[i:i+8]
                
                # Inizializziamo il byte compresso a 0
                compressed_byte = 0
                
                # Esaminiamo ogni byte del blocco
                for j, byte in enumerate(block):
                    if byte == 0x40:  # Se il byte è 0x40, imposta il bit corrispondente a 1
                        compressed_byte |= (1 << (7 - j))
                    elif byte == 0x39:  # Se il byte è 0x39, imposta il bit corrispondente a 0
                        compressed_byte &= ~(1 << (7 - j))
                
                # Scriviamo il byte compresso nel file di output
                outfile.write(bytes([compressed_byte]))

# Eseguiamo la compressione
compress_hero_levels('hero_levels_uncompressed.bin', 'hero_levels_compressed.bin')