#
# Copyright (C) 2008-2015 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

FF_PKGNAME?=$(notdir ${CURDIR})

PKG_NAME?=$(FF_PKGNAME)

##### deprecated LuCI-stuff 
# should be remove by time ...

LUCI_TYPE?=$(word 2,$(subst -, ,$(FF_PKGNAME)))
LUCI_BASENAME?=$(patsubst luci-$(LUCI_TYPE)-%,%,$(FF_PKGNAME))
LUCI_LANGUAGES:=$(sort $(filter-out templates,$(notdir $(wildcard ${CURDIR}/po/*))))
LUCI_DEFAULTS:=$(notdir $(wildcard ${CURDIR}/root/etc/uci-defaults/*))
LUCI_PKGARCH?=$(if $(realpath src/Makefile),,all)

include $(TOPDIR)/feeds/luci/luci-common.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
#  SUBMENU:=$(if $(LUCI_MENU.$(LUCI_TYPE)),$(LUCI_MENU.$(LUCI_TYPE)),$(LUCI_MENU.app))
#  TITLE:=$(if $(LUCI_TITLE),$(LUCI_TITLE),LuCI $(FF_PKGNAME) $(LUCI_TYPE))
#  DEPENDS:=$(LUCI_DEPENDS)
  SUBMENU:=TEST
  TITLE:=Freifunk $(FF_PKGNAME)
#  $(if $(LUCI_EXTRA_DEPENDS),EXTRA_DEPENDS:=$(LUCI_EXTRA_DEPENDS))
#  $(if $(LUCI_PKGARCH),PKGARCH:=$(LUCI_PKGARCH))
endef

ifneq ($(wildcard ${CURDIR}/src/Makefile),)
 MAKE_PATH := src/
 MAKE_VARS += FPIC="$(FPIC)" LUCI_VERSION="$(PKG_VERSION)" LUCI_GITBRANCH="$(PKG_GITBRANCH)"

 define Build/Compile
	$(call Build/Compile/Default,clean compile)
 endef
else
 define Build/Compile
 endef
endif

FF_BUILD_PACKAGES:=$(PKG_NAME)

$(foreach pkg,$(FF_BUILD_PACKAGES),$(eval $(call BuildPackage,$(pkg))))
