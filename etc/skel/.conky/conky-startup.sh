#!/bin/sh

if [ "$DESKTOP_SESSION" = "(null)" ]; then 
   sleep 20s
   killall conky
   cd "$HOME/.conky/Green Apple Desktop"
   conky -c "$HOME/.conky/Green Apple Desktop/Gotham" &
   exit 0
fi
if [ "$DESKTOP_SESSION" = "(null)" ]; then 
   sleep 20s
   killall conky
   cd "$HOME/.conky/Gotham"
   conky -c "$HOME/.conky/Gotham/Gotham" &
   exit 0
fi
if [ "$DESKTOP_SESSION" = "mate" ]; then 
   sleep 10s
   killall conky
   cd "$HOME/.conky/Gotham"
   conky -c "$HOME/.conky/Gotham/Gotham" &
   exit 0
fi
