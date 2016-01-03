ARCHS = armv7 arm64
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk

TWEAK_NAME = PowerInformer
PowerInformer_FILES = Tweak.xm
PowerInformer_FRAMEWORKS = UIKit

BUNDLE_NAME = PowerInformerSettings
PowerInformerSettings_FILES = PIPreferencePane.mm
PowerInformerSettings_FRAMEWORKS = UIKit
PowerInformerSettings_PRIVATE_FRAMEWORKS = Preferences
PowerInformerSettings_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 backboardd"
include $(THEOS_MAKE_PATH)/aggregate.mk
