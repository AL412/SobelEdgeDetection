from PIL import Image

# Config
image_path = "file.jpeg" #Replace with image file name
mif_path = "image_rom.mif"
width, height = 128, 128  # Target image size
depth = width * height  # Total number of pixels
data_width = 8

# Load and convert image
img = Image.open(image_path).convert('L')  # Convert to grayscale
img = img.resize((width, height))          # Resize if needed

pixels = list(img.getdata())

# Write to .mif
with open(mif_path, 'w') as f:
    f.write(f"WIDTH={data_width};\n")
    f.write(f"DEPTH={depth};\n\n")
    f.write("ADDRESS_RADIX=UNS;\n")
    f.write("DATA_RADIX=HEX;\n\n")
    f.write("CONTENT BEGIN\n")

    for addr, pixel in enumerate(pixels):
        f.write(f"    {addr} : {pixel:02X};\n")

    f.write("END;\n")

print(f"Successfully wrote {depth} pixels to {mif_path}")
