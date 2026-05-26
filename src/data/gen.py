import math

BITS_PER_CHANNEL = 8  # Set to 8 for 24-bit (HDMI/DVI) or 4 for 12-bit (VGA)

# Sizes
BALL_SIZE = 32
PADDLE_W = 16
PADDLE_H = 96
CORNER_RADIUS = 6
BORDER_THICKNESS = 2

# Colors (RGB, 0-255 scale - will be downsampled automatically if using 4-bit)
COLOR_BG    = (0, 0, 0)
COLOR_WHITE = (255, 255, 255)

# Ball Colors
BALL_BASE_COLOR = (255, 100, 100) # Soft Red

# Paddle 1 Colors (Left)
P1_INNER_COLOR  = (100, 255, 100) # Light Green
P1_BORDER_COLOR = (0, 150, 0)     # Dark Green

# Paddle 2 Colors (Right)
P2_INNER_COLOR  = (100, 150, 255) # Light Blue
P2_BORDER_COLOR = (0, 50, 180)    # Dark Blue

# ==========================================
# HELPER FUNCTIONS
# ==========================================
def blend_color(c1, c2, factor):
    """Blends c1 to c2. Factor 0.0 = c1, 1.0 = c2"""
    return tuple(int(c1[i] * (1 - factor) + c2[i] * factor) for i in range(3))

def generate_palette():
    """Generates the 16-color RGB palette map"""
    pal = [COLOR_BG, COLOR_WHITE]
    
    # Ball (Indices 2 to 5)
    pal.append(BALL_BASE_COLOR)
    pal.append(blend_color(BALL_BASE_COLOR, COLOR_BG, 0.4))
    pal.append(blend_color(BALL_BASE_COLOR, COLOR_BG, 0.7))
    pal.append(blend_color(BALL_BASE_COLOR, COLOR_BG, 0.9))
    
    # Paddle 1 (Indices 6 to 10)
    pal.append(P1_INNER_COLOR)
    pal.append(P1_BORDER_COLOR)
    pal.append(blend_color(P1_BORDER_COLOR, COLOR_BG, 0.4))
    pal.append(blend_color(P1_BORDER_COLOR, COLOR_BG, 0.7))
    pal.append(blend_color(P1_BORDER_COLOR, COLOR_BG, 0.9))

    # Paddle 2 (Indices 11 to 15)
    pal.append(P2_INNER_COLOR)
    pal.append(P2_BORDER_COLOR)
    pal.append(blend_color(P2_BORDER_COLOR, COLOR_BG, 0.4))
    pal.append(blend_color(P2_BORDER_COLOR, COLOR_BG, 0.7))
    pal.append(blend_color(P2_BORDER_COLOR, COLOR_BG, 0.9))
    
    return pal

def get_ball_pixel(x, y, size):
    """Returns the palette index for a ball pixel using SDF"""
    cx, cy = size / 2.0 - 0.5, size / 2.0 - 0.5
    radius = size / 2.0 - 1.5 
    
    dist = math.hypot(x - cx, y - cy) - radius
    
    if dist <= -1.0:   return 2 # Base
    elif dist <= -0.3: return 3 # AA1
    elif dist <= 0.4:  return 4 # AA2
    elif dist <= 1.2:  return 5 # AA3
    else:              return 0 # BG

def get_paddle_pixel(x, y, w, h, base_idx):
    """Returns the palette index for a paddle pixel using Rounded Box SDF"""
    cx, cy = w / 2.0 - 0.5, h / 2.0 - 0.5
    
    bx = w / 2.0 - CORNER_RADIUS - 1.0
    by = h / 2.0 - CORNER_RADIUS - 1.0
    
    dx = abs(x - cx) - bx
    dy = abs(y - cy) - by
    
    dist = math.hypot(max(dx, 0.0), max(dy, 0.0)) + min(max(dx, dy), 0.0) - CORNER_RADIUS
    
    if dist <= -BORDER_THICKNESS - 0.5: return base_idx      # Inner
    elif dist <= -0.5:                  return base_idx + 1  # Border
    elif dist <= 0.1:                   return base_idx + 2  # AA1
    elif dist <= 0.6:                   return base_idx + 3  # AA2
    elif dist <= 1.2:                   return base_idx + 4  # AA3
    else:                               return 0             # BG

def save_sprite(filename, w, h, pixel_func, *args):
    """Generates the sprite and saves to a hex text file"""
    with open(filename, 'w') as f:
        for y in range(h):
            row = []
            for x in range(w):
                idx = pixel_func(x, y, *args)
                row.append(f"{idx:X}") 
            f.write(" ".join(row) + "\n")
    print(f"Saved {filename} ({w}x{h})")

def save_palette_hex(filename, pal, bits_per_channel):
    """Saves the palette as a flat hex file for VHDL ROM initialization"""
    with open(filename, 'w') as f:
        for color in pal:
            if bits_per_channel == 8:
                # 24-bit format (e.g., FFFFFF)
                hex_color = f"{color[0]:02X}{color[1]:02X}{color[2]:02X}"
            elif bits_per_channel == 4:
                # 12-bit format (e.g., FFF) - bitshift by 4 to map 0-255 to 0-15
                hex_color = f"{color[0]>>4:1X}{color[1]>>4:1X}{color[2]>>4:1X}"
            else:
                raise ValueError("Only 4 or 8 bits per channel are supported.")
            
            f.write(f"{hex_color}\n")
    print(f"Saved {filename} ({bits_per_channel}-bits per channel)")

# ==========================================
# MAIN EXECUTION
# ==========================================
if __name__ == "__main__":
    palette = generate_palette()
    save_palette_hex("palette.hex", palette, BITS_PER_CHANNEL)
    
    save_sprite("ball.hex", BALL_SIZE, BALL_SIZE, get_ball_pixel, BALL_SIZE)
    save_sprite("paddle_left.hex", PADDLE_W, PADDLE_H, get_paddle_pixel, PADDLE_W, PADDLE_H, 6)
    save_sprite("paddle_right.hex", PADDLE_W, PADDLE_H, get_paddle_pixel, PADDLE_W, PADDLE_H, 11)
    
    print("\nAll ROM files generated successfully!")