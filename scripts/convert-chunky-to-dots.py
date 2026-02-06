#!/usr/bin/python

def extract_vertical_color_changes(input_file, output_file):
    """
    Reads a 128x64 8-bit image from 'input_file' and writes per-column color-change
    data to 'output_file'.
    
    Each column's data is encoded as:
       [count_of_changes] [y1] [y2] ... [y_count]
    """
    WIDTH = 144
    HEIGHT = 64
    
    # --- Read all bytes ---
    with open(input_file, "rb") as f:
        data = f.read()
    
    # Quick sanity check
    expected_size = WIDTH * HEIGHT
    if len(data) != expected_size:
        raise ValueError(
            f"Input file must be exactly {expected_size} bytes "
            f"(got {len(data)} bytes instead)."
        )
    
    # --- Reshape into a 2D array [row][column] in row-major order ---
    # image[row][column]
    image = []
    idx = 0
    for row in range(HEIGHT):
        row_data = data[idx : idx + WIDTH]
        image.append(row_data)
        idx += WIDTH
    
    # --- For each column, find vertical color changes ---
    output_bytes = bytearray()
    
    for x in range(WIDTH):
        changes = []
        
        # Compare row y with row (y-1)
        for y in range(1, HEIGHT):
            if image[y][x] != image[y - 1][x]:
                changes.append(y)
        
        # First byte: number of changes
        output_bytes.append(len(changes))
        # Subsequent bytes: row indices where changes occur
        for y_change in changes:
            output_bytes.append(y_change)
    
    # --- Write results to the output file ---
    with open(output_file, "wb") as f:
        f.write(output_bytes)


if __name__ == "__main__":
    # Example usage
    import sys

    if len(sys.argv) < 3:
        print(f"Usage: python {sys.argv[0]} <input.bin> <output.bin>")
        sys.exit(1)

    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    extract_vertical_color_changes(input_filename, output_filename)
    print(f"Wrote per-column color-change data to {output_filename}")
