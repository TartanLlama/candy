import os
import shutil

os.mkdir("candy")
folders = ["modules", "sprites"]
for folder in folders:
    shutil.copytree(folder, "candy/" + folder)

files =  ["mod.lua", "mod-icon.png"]
for file in files:
    shutil.copy(file, "candy")

shutil.make_archive("candy", "zip", "candy")
shutil.rmtree("candy")