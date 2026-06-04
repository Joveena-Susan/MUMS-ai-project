import os

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = content.replace('.withOpacity(', '.withValues(alpha: ')

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

directory = r"c:\Users\jeffy\Downloads\ui_flutter\lib"
for root, _, files in os.walk(directory):
    for filename in files:
        if filename.endswith(".dart"):
            process_file(os.path.join(root, filename))

print("withOpacity modifications complete.")
