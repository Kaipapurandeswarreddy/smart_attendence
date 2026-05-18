import os
import re

def fix_ui(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if not file.endswith('.dart'):
                continue
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            new_content = content
            
            # Fix logos: replace gradient with solid white
            logo_gradient = r'gradient:\s*const\s*LinearGradient\(\s*colors:\s*\[Color\(0xFF6C63FF\),\s*Color\(0xFF3F3D56\)\],\s*\),'
            new_content = re.sub(logo_gradient, 'color: Colors.white,', new_content)
            
            # Fix other logos (like the one in admin screen which has orange/red)
            admin_logo_gradient = r'gradient:\s*const\s*LinearGradient\(\s*colors:\s*\[Color\(0xFFFF6B6B\),\s*Color\(0xFFEE5A24\)\],\s*\),'
            new_content = re.sub(admin_logo_gradient, 'color: Colors.white,', new_content)
            
            if content != new_content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed logos in {path}")

if __name__ == '__main__':
    fix_ui(r'd:\smart_atten\attendance_system\frontend\attendance_app\lib')
