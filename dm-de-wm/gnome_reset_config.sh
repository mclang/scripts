#!/bin/bash
# BEWARE:
# Finds and deletes __ALL__ Gnome 3 things under user home directory!
#

# To back up and reset GNOME3:
# mkdir ./.old-gnome-config/
# mv ./.gnome* .gconf* ./.metacity ./.cache ./.dbus ./.dmrc ./.mission-control ./.thumbnails ~/.config/dconf/* ./.old-gnome-config/

#
# tar cvzf gnome-config-backup.tgz ~/.gnome* ~/.gconf* ~/.metacity ~/.cache ~/.dbus ~/.dmrc ~/.mission-control ~/.thumbnails ~/.config/dconf/
#
# tar cvzf gnome-config-backup.tgz ~/.gnome* ~/.dmrc ~/.thumbnails ~/.config/dconf/
#

  979  2017-05-17 22:15:27 - mkdir backup-gnome
  980  2017-05-17 22:15:46 - mv .gnome* backup-gnome/
  981  2017-05-17 22:16:00 - find . -iname gnome -print
  982  2017-05-17 22:18:02 - mv .config/gconf backup-gnome/
  983  2017-05-17 22:18:13 - rm -rf .config/Atom/
  984  2017-05-17 22:18:18 - rm -rf .config/atril/
  985  2017-05-17 22:18:31 - rm -rf .config/btsync/
  986  2017-05-17 22:18:38 - rm -rf .config/caja/
  987  2017-05-17 22:18:52 - rm -rf .config/dconf/
  988  2017-05-17 22:19:03 - rm -rf .config/eog/
  989  2017-05-17 22:19:32 - mv .config/gnome-* backup-gnome/
  990  2017-05-17 22:19:47 - rm -rf .config/KeePass/
  991  2017-05-17 22:20:01 - rm -rf .config/keepassx
  992  2017-05-17 22:20:03 - rm -rf .config/keepassxc/

2017-05-21 15:42:51
rm -rf ~/.gnome* ~/.gconf* ~/.metacity ~/.dbus/ ~/.dmrc ~/.mission-control ~/.thumbnails/ ~/.config/dconf/ 
rm -rf ~/.cache/gnome-*
rm -rf ~/.cache/*
