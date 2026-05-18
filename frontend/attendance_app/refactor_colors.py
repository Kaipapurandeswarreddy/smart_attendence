import os
import re

def refactor_colors(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Replace Colors.white with Colors.black87
                # but handle Colors.white.withOpacity carefully
                
                # First, Colors.white.withOpacity -> Colors.black.withOpacity
                content = content.replace('Colors.white.withOpacity', 'Colors.black.withOpacity')
                
                # Colors.white10 -> Colors.black12
                content = content.replace('Colors.white10', 'Colors.black12')
                content = content.replace('Colors.white12', 'Colors.black12')
                content = content.replace('Colors.white24', 'Colors.black26')
                content = content.replace('Colors.white38', 'Colors.black38')
                content = content.replace('Colors.white54', 'Colors.black54')
                content = content.replace('Colors.white60', 'Colors.black54')
                content = content.replace('Colors.white70', 'Colors.black87')
                
                # Finally Colors.white -> Colors.black87
                content = content.replace('Colors.white', 'Colors.black87')
                
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Refactored {path}")

if __name__ == '__main__':
    refactor_colors(r'd:\smart_atten\attendance_system\frontend\attendance_app\lib')
