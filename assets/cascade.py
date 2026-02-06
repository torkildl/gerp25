import matplotlib.pyplot as plt
import matplotlib.animation as animation

# ---------------------------
# 1) Parameters
# ---------------------------

GRAVITY     = 300.0    # px/sec^2 (positive => downward in this inverted system)
BOUNCE_DAMP = 0.6      # how much velocity is kept after each bounce
FPS         = 30
DT          = 1.0 / FPS
DURATION    = 4.0      # seconds of animation

SCREEN_HEIGHT = 300    # We’ll show 0..300 in vertical space
RIBBON_HEIGHT = 32
FLOOR_Y       = 200    # The "floor" or base line at y=200

# The ribbon’s initial state
ribbon_y = 50.0        # Start near the top (y=50)
ribbon_v = 0.0         # Initial velocity

# ---------------------------
# 2) Set up plotting
# ---------------------------

fig, ax = plt.subplots(figsize=(4, 4))
ax.set_xlim(0, 200)                     # Just a simple width
ax.set_ylim(0, SCREEN_HEIGHT)           # 0 = top, 300 = bottom
ax.set_title("Single Ribbon, Inverted Y-axis")

# We'll represent the ribbon as one rectangle
ribbon_rect = plt.Rectangle(
    (50, ribbon_y),   # (x, y) bottom-left corner
    100,              # width
    RIBBON_HEIGHT,    # height
    color="blue"
)
ax.add_patch(ribbon_rect)

# ---------------------------
# 3) Update function
# ---------------------------

def update(frame):
    global ribbon_y, ribbon_v

    # Apply gravity
    ribbon_v += GRAVITY * DT
    # Update position
    ribbon_y += ribbon_v * DT

    # Check collision with the floor:
    # The ribbon's bottom edge is at ribbon_y,
    # so if (ribbon_y + RIBBON_HEIGHT) goes beyond FLOOR_Y, it's colliding.
    if (ribbon_y + RIBBON_HEIGHT) > FLOOR_Y:
        # Move it back so it's exactly on the floor
        ribbon_y = FLOOR_Y - RIBBON_HEIGHT
        # Reverse velocity with damping
        ribbon_v = -ribbon_v * BOUNCE_DAMP

    y_physics = ribbon_y
    # Update the rectangle's display position
    ribbon_rect.set_xy((50, ribbon_y))

    return [ribbon_rect]

# ---------------------------
# 4) Create and run the animation
# ---------------------------

anim = animation.FuncAnimation(
    fig,
    update,
    frames=int(DURATION * FPS),
    interval=1000 / FPS,
    blit=True
)

plt.show()
