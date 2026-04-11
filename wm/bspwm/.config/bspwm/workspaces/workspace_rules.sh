bspc rule -a Gimp desktop='^8' state=floating follow=on




# Workspace 2
bspc rule -a Chromium desktop='^2'
bspc rule -a Firefox desktop='^2'
bspc rule -a "Brave-browser-nightly" desktop='^2'

# Workspace 3
bspc rule -a "Code - OSS" desktop='^3' follow=on
bspc rule -a "Emacs" desktop='^3' follow=on
bspc rule -a "Sublime_text" desktop='^3' follow=on


# Workspace 4
bspc rule -a '@joplinapp-desktop' desktop='^4' follow=on
bspc rule -a 'Joplin' desktop='^4' follow=on
bspc rule -a 'XpdfReader' desktop='^4' follow=on
bspc rule -a "Evince" desktop='^4' follow=on

# Workspace 5
bspc rule -a "vlc" desktop='^5' follow=on

# Workspace 6
bspc rule -a "Steam" desktop='^6' follow=on

bspc rule -a mplayer2 state=floating
bspc rule -a Screenkey manage=off

bspc rule -a Kupfer.py focus=on