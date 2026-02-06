from PIL import Image, ImageDraw
import base64
from io import BytesIO

def generate_truchet_tile_16px(thickness=3):
    size = 16
    # Create a white 16×16 image
    img = Image.new("RGB", (size, size), "white")
    draw = ImageDraw.Draw(img)
    
    # Draw thicker arcs (“S” shape):
    #   Arc 1 = top-left quadrant (90° → 180°)
    #   Arc 2 = bottom-right quadrant (270° → 360°)
    draw.arc((0, 0, size, size), start=90, end=180, fill="black", width=thickness)
    draw.arc((0, 0, size, size), start=270, end=360, fill="black", width=thickness)

    return img

if __name__ == "__main__":
    tile_img = generate_truchet_tile_16px(thickness=3)
    
    # Option 1: Save to disk
    tile_img.save("truchet_16px.png", "PNG")
    
    # Option 2: Print base64-encoded PNG to console (so you can copy/paste)
    buffer = BytesIO()
    tile_img.save(buffer, format="PNG")
    b64_data = base64.b64encode(buffer.getvalue()).decode("ascii")
    print("data:image/png;base64," + b64_data)
