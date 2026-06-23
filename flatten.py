import os
import shutil

src_dir = r"c:\src\DnevnikFlutter\src\Geometry"
dest_dir = r"c:\src\DnevnikFlutter\assets\Geometry"

if not os.path.exists(dest_dir):
    os.makedirs(dest_dir)

for root, dirs, files in os.walk(src_dir):
    for file in files:
        if file.endswith('.png'):
            # root is something like c:\src\DnevnikFlutter\src\Geometry\100
            dir_name = os.path.basename(root)
            new_name = f"{dir_name}_{file}"
            src_path = os.path.join(root, file)
            dest_path = os.path.join(dest_dir, new_name)
            shutil.copy2(src_path, dest_path)
            print(f"Copied {src_path} -> {dest_path}")
