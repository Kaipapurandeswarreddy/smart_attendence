import socket
import re
import os

def get_local_ip():
    # Create a dummy socket to find the local IP that routes to the internet
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def update_flutter_config(ip):
    config_path = os.path.join(
        "frontend", "attendance_app", "lib", "config", "app_config.dart"
    )
    
    if not os.path.exists(config_path):
        print(f"Could not find {config_path}")
        return

    with open(config_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Regex to find and replace the backendBaseUrl
    # Matches: static const String backendBaseUrl = 'http://192.168.1.1:8000';
    pattern = r"(static const String backendBaseUrl =\s*)'http://[\d\.]+:\d+'"
    replacement = rf"\1'http://{ip}:8000'"
    
    new_content = re.sub(pattern, replacement, content)

    if new_content != content:
        with open(config_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"✅ Successfully updated app_config.dart to use IP: {ip}")
    else:
        print(f"ℹ️ IP is already up to date ({ip}) or regex didn't match.")

if __name__ == "__main__":
    current_ip = get_local_ip()
    print(f"🔍 Found current Wi-Fi IP: {current_ip}")
    update_flutter_config(current_ip)
