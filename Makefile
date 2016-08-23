THEOS_DEVICE_IP = 192.168.1.100
TARGET = iphone:latest:7.0
ARCHS = arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatTool
WeChatTool_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 WeChat"
