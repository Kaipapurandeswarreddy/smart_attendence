import re

def fix_admin_home_screen():
    path = r'd:\smart_atten\attendance_system\frontend\attendance_app\lib\screens\admin_home_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Replace the tab bar container background
    content = re.sub(
        r'color:\s*Colors\.black\.withOpacity\(0\.06\),\s*borderRadius:\s*BorderRadius\.circular\(14\),',
        r'color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],',
        content
    )

    # 2. Replace the Dropdown button background
    content = re.sub(
        r'color:\s*Colors\.black\.withOpacity\(0\.05\),\s*borderRadius:\s*BorderRadius\.circular\(14\),',
        r'color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],',
        content
    )

    # 3. Replace the QR result background
    content = re.sub(
        r'color:\s*Colors\.black\.withOpacity\(0\.08\),\s*borderRadius:\s*BorderRadius\.circular\(20\),',
        r'color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],',
        content
    )
    
    # 4. Replace list item backgrounds (e.g. students list)
    content = re.sub(
        r'color:\s*Colors\.black\.withOpacity\(0\.04\),\s*borderRadius:\s*BorderRadius\.circular\(12\),',
        r'color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 3))],',
        content
    )

    # 5. Dashboard card backgrounds
    content = re.sub(
        r'color:\s*Colors\.black\.withOpacity\(0\.1\),\s*borderRadius:\s*BorderRadius\.circular\(16\),',
        r'color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],',
        content
    )

    # 6. Session container backgrounds
    content = re.sub(
        r'color:\s*Colors\.black\.withOpacity\(0\.05\),\s*borderRadius:\s*BorderRadius\.circular\(12\),',
        r'color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 3))],',
        content
    )
    
    # 7. Thin stat bar
    content = re.sub(
        r'decoration:\s*BoxDecoration\(\s*color:\s*Colors\.black\.withOpacity\(0\.05\),\s*borderRadius:\s*BorderRadius\.circular\(12\),\s*\),',
        r'decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 3))]),',
        content
    )
    
    # Replace expansion tile background
    content = re.sub(
        r'decoration:\s*BoxDecoration\(\s*color:\s*Colors\.black\.withOpacity\(0\.03\),\s*borderRadius:\s*BorderRadius\.circular\(14\),\s*\),',
        r'decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 3))]),',
        content
    )


    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Fixed admin home screen cards")

if __name__ == '__main__':
    fix_admin_home_screen()
