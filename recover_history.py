import os
import glob
import re

appdata = os.environ.get('APPDATA')
if appdata:
    history_dir = os.path.join(appdata, 'Code', 'User', 'History')
    if os.path.exists(history_dir):
        print('Searching in:', history_dir)
        import subprocess
        # powershell to find paths
        cmd = 'Get-ChildItem -Path "' + history_dir + '" -Recurse -File | Select-String -Pattern "_emailCtrl" -List | Select-Object -ExpandProperty Path'
        result = subprocess.run(['powershell', '-Command', cmd], capture_output=True, text=True)
        paths = result.stdout.strip().split('\n')
        paths = [p for p in paths if p.strip()]
        if paths:
            # find the one that also contains "Widget _content(double W, double H)"
            matches = []
            for p in paths:
                try:
                    with open(p, 'r', encoding='utf-8') as f:
                        c = f.read()
                        if 'Widget _content(double W, double H)' in c:
                            matches.append(p)
                except Exception:
                    pass
            if matches:
                # get latest
                latest = max(matches, key=os.path.getmtime)
                print('Found latest:', latest)
                with open(latest, 'r', encoding='utf-8') as f:
                    content = f.read()
                    idx = content.find('Widget _content(double W, double H)')
                    if idx != -1:
                        print('FOUND _content!')
                        end_idx = content.find('Widget _background(double W, double H)', idx)
                        if end_idx == -1:
                            end_idx = content.find('class _GlassButton', idx)
                        print(content[idx:end_idx])
            else:
                print('No match for _content found in history.')
        else:
            print('No match found.')
    else:
        print('No history dir.')
