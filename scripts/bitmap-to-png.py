import sys
import struct
import numpy as np
from PIL import Image

def read_bitplane_file(filename, width, num_planes=3):
    """Reads a raw Amiga bitplane file and converts it to a bitmap array."""
    with open(filename, "rb") as f:
        data = f.read()

    # Compute height based on file size and width (Amiga bitplanes are 16-pixel aligned)
    bytes_per_row = width // 8
    height = len(data) // (bytes_per_row * num_planes)

    print(f"Detected height: {height} pixels")

    # Create an empty array for the final indexed image
    image = np.zeros((height, width), dtype=np.uint8)

    # Extract bitplanes
    for y in range(height):
        for plane in range(num_planes):
            offset = (plane * height + y) * bytes_per_row
            row_data = data[offset:offset + bytes_per_row]

            # Convert each byte into 8 pixels
            for x_byte in range(bytes_per_row):
                byte = row_data[x_byte]
                for bit in range(8):
                    pixel_x = x_byte * 8 + (7 - bit)  # Amiga bit-order (MSB first)
                    image[y, pixel_x] |= ((byte >> bit) & 1) << plane

    return image, width, height

def generate_palette(num_planes):
    """Creates a simple grayscale or EHB-style color palette."""
    num_colors = 2 ** num_planes
    palette = []

    for i in range(num_colors):
        gray = int((i / (num_colors - 1)) * 255)  # Scale to 8-bit grayscale
        palette.extend([gray, gray, gray])  # RGB triplet

    return palette

def save_as_png(image_data, width, height, num_planes, output_file):
    """Saves the image data as a PNG."""
    img = Image.fromarray(image_data, mode="P")
    
    # Generate grayscale palette
    palette = generate_palette(num_planes)
    img.putpalette(palette)

    img.save(output_file)
    print(f"Saved PNG: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python amiga_bitplane_converter.py <bitplane_file> <width> [num_planes]")
        sys.exit(1)

    bitplane_file = sys.argv[1]
    width = int(sys.argv[2])
    num_planes = int(sys.argv[3]) if len(sys.argv) > 3 else 3  # Default to 3-bitplanes

    image_data, width, height = read_bitplane_file(bitplane_file, width, num_planes)

    output_file = bitplane_file.rsplit('.', 1)[0] + ".png"
    save_as_png(image_data, width, height, num_planes, output_file)

if __name__ == "__main__":
    main()
