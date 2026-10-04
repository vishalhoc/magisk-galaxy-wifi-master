#!/system/bin/sh
# Launch Galaxy Wi-Fi Master Web Control Panel via Magisk Action Button
am start -a android.intent.action.VIEW -d "http://127.0.0.1:8095" 2>/dev/null
exit 0
