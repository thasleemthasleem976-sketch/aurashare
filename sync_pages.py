import os
import shutil
import subprocess

base_dir = os.path.dirname(os.path.abspath(__file__))
web_dir = os.path.join(base_dir, "web")
docs_dir = os.path.join(base_dir, "docs")
os.makedirs(docs_dir, exist_ok=True)

# Rebuild the offline zip bundle first
subprocess.run(["python", "create_offline_bundle.py"], cwd=base_dir, check=True)

# Files to sync to root and docs
for item in os.listdir(web_dir):
    src = os.path.join(web_dir, item)
    dst_root = os.path.join(base_dir, item)
    dst_docs = os.path.join(docs_dir, item)
    
    if os.path.isfile(src):
        shutil.copy2(src, dst_root)
        shutil.copy2(src, dst_docs)
    elif os.path.isdir(src):
        if os.path.exists(dst_root):
            shutil.rmtree(dst_root)
        shutil.copytree(src, dst_root)
        if os.path.exists(dst_docs):
            shutil.rmtree(dst_docs)
        shutil.copytree(src, dst_docs)

print("Synchronized all web assets to root / and docs/ successfully!")
