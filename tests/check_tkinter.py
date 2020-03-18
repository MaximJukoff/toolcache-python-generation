import sys

if int(sys.version_info.major) == 3:
    import tkinter as tk
else:
    import Tkinter as tk

print(tk.TkVersion)