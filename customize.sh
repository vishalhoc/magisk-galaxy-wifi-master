#!/system/bin/sh
ui_print "********************************************"
ui_print "  Galaxy Wi-Fi Master & Web Control Panel   "
ui_print "                  by hoc                    "
ui_print "********************************************"
ui_print " "
ui_print "Target Device: Samsung Galaxy M32 5G (MT6853)"
ui_print "Wi-Fi Chip:    MediaTek MT6631 / CONNSYS 2.0"
ui_print " "
ui_print "[*] Installing 256-QAM (TurboQAM) Enabler..."
ui_print "[*] Installing Continuous Access Mode (CAM) Engine..."
ui_print "[*] Unlocking DFS & 5GHz Indoor Channels..."
ui_print "[*] Configuring Packet Aggregation & TCP BBR..."
ui_print "[*] Installing Web Control Panel (Port 8095)..."
ui_print " "

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/system/bin 0 0 0755 0755
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/action.sh 0 0 0755
set_perm $MODPATH/web/cgi-bin/api.cgi 0 0 0755

ui_print " "
ui_print "✅ Installation successful!"
ui_print "   Web Control Panel will run at: http://127.0.0.1:8095"
ui_print "   Tap 'Action' button or run 'su -c wifi_master' in shell."
ui_print "   Please REBOOT your device to activate overlays."
ui_print "=========================================="
