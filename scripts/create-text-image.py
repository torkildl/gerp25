import os
import math
import argparse
from PIL import Image, ImageDraw, ImageFont

def round_up_to_nearest(value, base=16):
    """Rounds up value to the nearest multiple of 'base'."""
    return math.ceil(value / base) * base

def create_text_image(text, font_path, font_size, output_path, padding=10):
    """
    Creates a black/white cropped image with centered multiline text.

    :param text: The text to render.
    :param font_path: Path to the .ttf or .otf font file.
    :param font_size: Font size in pixels.
    :param output_path: Path to save the generated image.
    :param padding: Padding around the text.
    """
    # Load the font (supports TTF and OTF)
    try:
        font = ImageFont.truetype(font_path, font_size)
    except IOError:
        print("❌ Error: Font file not found or invalid.")
        return

    # Create a temporary image to measure text size
    temp_img = Image.new('1', (1, 1), 1)  # '1' mode for black/white
    draw = ImageDraw.Draw(temp_img)

    # Measure multiline text size
    lines = text.split("\\n")  # Allow newlines in CLI
    max_line_width = max(draw.textsize(line, font=font)[0] for line in lines)
    total_height = sum(draw.textsize(line, font=font)[1] for line in lines) + (len(lines) - 1) * 5  # Line spacing

    # Apply padding
    text_width = max_line_width + 2 * padding
    text_height = total_height + 2 * padding

    # Round width up to the nearest multiple of 16
    text_width = round_up_to_nearest(text_width, 16)

    # Create final black/white image
    img = Image.new('1', (text_width, text_height), 1)  # 1 = white background
    draw = ImageDraw.Draw(img)

    # Draw text line by line, centered
    y_offset = padding
    for line in lines:
        line_width, line_height = draw.textsize(line, font=font)
        x = (text_width - line_width) // 2
        draw.text((x, y_offset), line, fill=0, font=font)  # 0 = black text
        y_offset += line_height + 5  # Move down for next line

    # Save the image
    img.save(output_path)
    print(f"✅ Image saved to {output_path} (Size: {img.size})")

# Command-line interface using argparse
def main():
    parser = argparse.ArgumentParser(description="Generate a black/white image with text.")

    parser.add_argument("-t", "--text", required=True, help="The text to render (use '\\n' for new lines)")
    parser.add_argument("-f", "--font", required=True, help="Path to the font file (.ttf or .otf)")
    parser.add_argument("-s", "--size", type=int, required=True, help="Font size in pixels")
    parser.add_argument("-o", "--output", required=True, help="Output image filename (e.g., output.png)")
    parser.add_argument("-p", "--padding", type=int, default=10, help="Padding around the text (default: 10)")

    args = parser.parse_args()

    # Validate font file existence
    if not os.path.isfile(args.font):
        print("❌ Error: Font file not found!")
        return

    create_text_image(args.text, args.font, args.size, args.output, args.padding)

if __name__ == "__main__":
    main()
