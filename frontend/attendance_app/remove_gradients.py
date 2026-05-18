import os
import re

def remove_dark_gradients(directory):
    gradient_pattern = re.compile(
        r'decoration:\s*const\s*BoxDecoration\(\s*'
        r'gradient:\s*LinearGradient\(\s*'
        r'begin:\s*Alignment\.topCenter,\s*'
        r'end:\s*Alignment\.bottomCenter,\s*'
        r'colors:\s*\[Color\(0xFF0F0C29\),\s*Color\(0xFF302B63\),\s*Color\(0xFF24243E\)\],\s*'
        r'\),\s*'
        r'\),', re.MULTILINE
    )

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()

                new_content = gradient_pattern.sub('', content)

                # Add backgroundColor: Colors.transparent, to Scaffolds if they don't have it
                # Specifically matching: return Scaffold(
                new_content = new_content.replace('return Scaffold(', 'return Scaffold(\n      backgroundColor: Colors.transparent,')

                if content != new_content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Removed gradient from {path}")

if __name__ == '__main__':
    remove_dark_gradients(r'd:\smart_atten\attendance_system\frontend\attendance_app\lib')
