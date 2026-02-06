import freetype
import matplotlib.pyplot as plt
import matplotlib.path as mpath
import matplotlib.patches as mpatches

def _outline_to_polygons(outline):
    """
    Convert a FreeType outline into a list of polygons.
    Each polygon corresponds to one contour in the glyph.
    """
    polygons = []
    start_idx = 0
    
    for end_idx in outline.contours:
        # contour endpoints are inclusive, so we add +1
        end_idx += 1
        contour_points = outline.points[start_idx:end_idx]
        
        # Convert to (x, y) tuples
        polygon = [(p[0], p[1]) for p in contour_points]
        polygons.append(polygon)
        
        start_idx = end_idx
    
    return polygons

def string_to_polygons_with_kerning(font_path, text, font_size=64):
    """
    Convert a string to polygons, placing glyphs left-to-right,
    taking kerning into account.
    
    :param font_path: Path to the TTF/OTF font file.
    :param text: The text string to render.
    :param font_size: Font size in points (approximately).
    :return: A list of polygons (each polygon is [(x, y), ...]),
             arranged in the correct positions to form the word.
    """
    face = freetype.Face(font_path)
    # Set the font size. FreeType uses 1/64th of a point.
    face.set_char_size(font_size * 64)
    
    pen_x = 0
    pen_y = 0
    all_polygons = []
    
    # Keep track of previous glyph index for kerning
    last_glyph_index = None
    
    for char in text:
        # Get glyph index for this character
        glyph_index = face.get_char_index(char)
        
        # Apply kerning if there's a previous glyph
        if last_glyph_index is not None:
            kerning = face.get_kerning(last_glyph_index, glyph_index, freetype.FT_KERNING_DEFAULT)
            # Kerning.x is 26.6 fixed-point, so shift right by 6
            pen_x += (kerning.x >> 6)
        
        # Load the glyph outline
        face.load_glyph(glyph_index, freetype.FT_LOAD_DEFAULT)
        outline = face.glyph.outline
        
        # Convert outline to polygons
        glyph_polygons = _outline_to_polygons(outline)
        
        # Offset polygons by the current pen position
        offset_polygons = []
        for polygon in glyph_polygons:
            offset_polygon = [(x + pen_x, y + pen_y) for (x, y) in polygon]
            offset_polygons.append(offset_polygon)
        
        # Append to the big list of polygons
        all_polygons.extend(offset_polygons)
        
        # Advance pen for the next character
        # face.glyph.advance.x is also in 26.6 fixed-point
        pen_x += (face.glyph.advance.x >> 6)
        
        last_glyph_index = glyph_index
    
    return all_polygons

def preview_polygons(polygons, invert_y=False):
    """
    Visualize polygons on a Matplotlib plot.
    
    :param polygons: List of polygons, each is [(x1, y1), (x2, y2), ...].
    :param invert_y: If True, flips the Y-axis so it increases downward.
    """
    fig, ax = plt.subplots()
    
    for polygon in polygons:
        if not polygon:
            continue
        
        # Build a Path for each polygon
        codes = [mpath.Path.MOVETO] + [mpath.Path.LINETO] * (len(polygon) - 1)
        path = mpath.Path(polygon, codes)
        
        # Draw as an unfilled (outlined) patch
        patch = mpatches.PathPatch(
            path,
            facecolor="none",
            edgecolor="black",
            linewidth=1
        )
        ax.add_patch(patch)
    
    ax.autoscale_view()
    ax.set_aspect('equal', 'datalim')
    
    if invert_y:
        ax.invert_yaxis()
    
    plt.title("Text as Polygons (with Kerning)")
    plt.xlabel("X coordinate")
    plt.ylabel("Y coordinate")
    plt.show()

if __name__ == "__main__":
    font_file = "MyFont.ttf"   # Update with your font path
    text = "Hello"
    
    polygons = string_to_polygons_with_kerning(font_file, text, font_size=72)
    preview_polygons(polygons, invert_y=False)  # Set True if you want Y to go downward
