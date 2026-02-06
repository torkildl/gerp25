from PIL import Image

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------
SOURCE_IMAGE_PATH = "../assets/font_end.png"  # Your actual font image
CHAR_WIDTH  = 8    # The width of each glyph's bounding box in the source
CHAR_HEIGHT = 16   # The height of each glyph
TARGET_WIDTH  = 32
TARGET_HEIGHT = 256 * CHAR_HEIGHT  # 256 chars * 16 px = 4096

# Output filenames
RAW_BITMAP_OUT  = "amiga_font_32x4096.raw"
WIDTH_TABLE_OUT = "amiga_font_widths.raw"
CHECK_PNG_OUT   = "amiga_font_32x4096.png"

# Are we writing the widths in big-endian (Motorola 68000 friendly)?
BIG_ENDIAN = True

# Example ASCII codes for special glyphs:
HEART_CODE       = 0x80
STAR_CODE        = 0x81
LOCOMOTIVE_CODE  = 0x82
CARRIAGE_CODE    = 0x83

# You must fill in the exact (gx, gy) for each glyph in your source image.
# Keys are ASCII codes (0..255); values are (x, y) in the source.
# If a glyph doesn’t exist, omit it or map to None so it remains blank.
glyph_positions = {
    # For example (completely fictional positions):
    0x20: (0,  0),   # Space
    0x21: (8,  0),   # '!'
    # ...
    HEART_CODE:      (0,  32),  # ♥
    STAR_CODE:       (8,  32),  # ★
    LOCOMOTIVE_CODE: (16, 32),  # locomotive
    CARRIAGE_CODE:   (24, 32),  # carriage
    # ...
}

# ---------------------------------------------------------
# FUNCTION: measure_glyph_width
# ---------------------------------------------------------
def measure_glyph_width(img):
    """
    Given a Pillow Image (mode '1') of a character sized CHAR_WIDTH x CHAR_HEIGHT,
    find the rightmost lit pixel (255) and return (that_x + 1) as the glyph's width.
    If the glyph is blank, returns 0.
    """
    pixels = img.load()
    max_x = -1
    for y in range(CHAR_HEIGHT):
        for x in range(CHAR_WIDTH):
            if pixels[x, y] != 0:  # lit pixel
                if x > max_x:
                    max_x = x
    return (max_x + 1) if max_x >= 0 else 0

# ---------------------------------------------------------
# MAIN SCRIPT
# ---------------------------------------------------------
def main():
    # 1) Load source image as 1-bit
    src = Image.open(SOURCE_IMAGE_PATH).convert("1")
    
    # 2) Create the tall output image: 32 px wide × 4096 px tall
    out = Image.new("1", (TARGET_WIDTH, TARGET_HEIGHT), 0)  # black background
    
    # 3) Prepare array to store widths (256 entries)
    char_widths = [0]*256
    
    # 4) For each ASCII code 0..255, extract the glyph (if it exists)
    for codepoint in range(256):
        out_y = codepoint * CHAR_HEIGHT
        
        # Check if we have a known position for this codepoint
        coords = glyph_positions.get(codepoint, None)
        if coords is not None:
            gx, gy = coords
            # Crop the glyph from the source
            char_img = src.crop((gx, gy, gx + CHAR_WIDTH, gy + CHAR_HEIGHT))
            # Measure used width
            w = measure_glyph_width(char_img)
            char_widths[codepoint] = w
            # Paste left-aligned at x=0
            out.paste(char_img, (0, out_y))
        else:
            # No glyph => blank row => width=0
            char_widths[codepoint] = 0
    
    # 5) Write the 32×4096 raw bitmap (packed bits)
    with open(RAW_BITMAP_OUT, "wb") as f_bmp:
        pix = out.load()
        for y in range(TARGET_HEIGHT):
            row_byte = 0
            bit_count = 0
            row_data = bytearray()
            for x in range(TARGET_WIDTH):
                pixel_val = 1 if pix[x, y] != 0 else 0
                # Shift left by 1 and add the bit (left -> right packing)
                row_byte = (row_byte << 1) | pixel_val
                bit_count += 1
                if bit_count == 8:
                    row_data.append(row_byte & 0xFF)
                    row_byte = 0
                    bit_count = 0
            f_bmp.write(row_data)
    
    # 6) Write the 256-word width table
    with open(WIDTH_TABLE_OUT, "wb") as f_w:
        for w in char_widths:
            # optional clamp if needed
            if w > 32:
                w = 32
            if BIG_ENDIAN:
                # High byte, then low byte
                f_w.write(bytes([(w >> 8) & 0xFF, w & 0xFF]))
            else:
                # Low byte, then high byte
                f_w.write(bytes([w & 0xFF, (w >> 8) & 0xFF]))
    
    # 7) Write a PNG (32×4096) to inspect visually
    out.save(CHECK_PNG_OUT, "PNG")
    
    print("Done!")
    print(f"  - Bitmap  : {RAW_BITMAP_OUT}  (32x4096, raw 1-bit data)")
    print(f"  - Widths  : {WIDTH_TABLE_OUT} (256 words, for spacing)")
    print(f"  - Check PNG: {CHECK_PNG_OUT}  (32x4096 PNG)")

if __name__ == "__main__":
    main()
