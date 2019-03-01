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

# Language code titles
LUCI_LANG.ca=Català (Catalan)
LUCI_LANG.cs=Čeština (Czech)
LUCI_LANG.de=Deutsch (German)
LUCI_LANG.el=Ελληνικά (Greek)
LUCI_LANG.en=English
LUCI_LANG.es=Español (Spanish)
LUCI_LANG.fr=Français (French)
LUCI_LANG.he=עִבְרִית (Hebrew)
LUCI_LANG.hu=Magyar (Hungarian)
LUCI_LANG.it=Italiano (Italian)
LUCI_LANG.ja=日本語 (Japanese)
LUCI_LANG.ko=한국어 (Korean)
LUCI_LANG.ms=Bahasa Melayu (Malay)
LUCI_LANG.no=Norsk (Norwegian)
LUCI_LANG.pl=Polski (Polish)
LUCI_LANG.pt-br=Português do Brasil (Brazialian Portuguese)
LUCI_LANG.pt=Português (Portuguese)
LUCI_LANG.ro=Română (Romanian)
LUCI_LANG.ru=Русский (Russian)
LUCI_LANG.sk=Slovenčina (Slovak)
LUCI_LANG.sv=Svenska (Swedish)
LUCI_LANG.tr=Türkçe (Turkish)
LUCI_LANG.uk=Українська (Ukrainian)
LUCI_LANG.vi=Tiếng Việt (Vietnamese)
LUCI_LANG.zh-cn=中文 (Chinese)
LUCI_LANG.zh-tw=臺灣華語 (Taiwanese)

# Submenu titles
LUCI_MENU.col=1. Collections
LUCI_MENU.mod=2. Modules
LUCI_MENU.app=3. Applications
LUCI_MENU.theme=4. Themes
LUCI_MENU.proto=5. Protocols
LUCI_MENU.lib=6. Libraries

PKG_VERSION?=$(if $(DUMP),x,$(strip $(shell \
	if svn info >/dev/null 2>/dev/null; then \
		revision="svn-r$$(LC_ALL=C svn info | sed -ne 's/^Revision: //p')"; \
	elif git log -1 >/dev/null 2>/dev/null; then \
		revision="svn-r$$(LC_ALL=C git log -1 | sed -ne 's/.*git-svn-id: .*@\([0-9]\+\) .*/\1/p')"; \
		if [ "$$revision" = "svn-r" ]; then \
			set -- $$(git log -1 --format="%ct %h" --abbrev=7); \
			secs="$$(($$1 % 86400))"; \
			yday="$$(date --utc --date="@$$1" "+%y.%j")"; \
			revision="$$(printf 'git-%s.%05d-%s' "$$yday" "$$secs" "$$2")"; \
		fi; \
	else \
		revision="unknown"; \
	fi; \
	echo "$$revision" \
)))

PKG_GITBRANCH?=$(if $(DUMP),x,$(strip $(shell \
	variant="LuCI"; \
	if git log -1 >/dev/null 2>/dev/null; then \
		branch="$$(git branch --remote --verbose --no-abbrev --contains 2>/dev/null | \
			sed -rne 's|^[^/]+/([^ ]+) [a-f0-9]{40} .+$$|\1|p' | head -n1)"; \
		if [ "$$branch" != "master" ]; then \
			variant="LuCI $$branch branch"; \
		else \
			variant="LuCI Master"; \
		fi; \
	fi; \
	echo "$$variant" \
)))

PKG_RELEASE?=1
PKG_INSTALL:=$(if $(realpath src/Makefile),1)
PKG_BUILD_DEPENDS += lua/host luci-base/host LUCI_CSSTIDY:csstidy/host $(LUCI_BUILD_DEPENDS)
PKG_CONFIG_DEPENDS += CONFIG_LUCI_SRCDIET CONFIG_LUCI_JSMIN CONFIG_LUCI_CSSTIDY

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=$(if $(LUCI_MENU.$(LUCI_TYPE)),$(LUCI_MENU.$(LUCI_TYPE)),$(LUCI_MENU.app))
  TITLE:=$(if $(LUCI_TITLE),$(LUCI_TITLE),LuCI $(LUCI_NAME) $(LUCI_TYPE))
  DEPENDS:=$(LUCI_DEPENDS)
  $(if $(LUCI_EXTRA_DEPENDS),EXTRA_DEPENDS:=$(LUCI_EXTRA_DEPENDS))
  $(if $(LUCI_PKGARCH),PKGARCH:=$(LUCI_PKGARCH))
endef

ifneq ($(LUCI_DESCRIPTION),)
 define Package/$(PKG_NAME)/description
   $(strip $(LUCI_DESCRIPTION))
 endef
endif

define Build/Prepare
	for d in luasrc htdocs root src; do \
	  if [ -d ./$$$$d ]; then \
	    mkdir -p $(PKG_BUILD_DIR)/$$$$d; \
		$(CP) ./$$$$d/* $(PKG_BUILD_DIR)/$$$$d/; \
	  fi; \
	done
	$(call Build/Prepare/Default)
endef

define Build/Configure
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

HTDOCS = /www
LUA_LIBRARYDIR = /usr/lib/lua
LUCI_LIBRARYDIR = $(LUA_LIBRARYDIR)/luci

define SubstituteVersion
	$(FIND) $(1) -type f -name '*.htm' | while read src; do \
		$(SED) 's/<%# *\([^ ]*\)PKG_VERSION *%>/\1$(PKG_VERSION)/g' \
		    -e 's/"\(<%= *\(media\|resource\) *%>[^"]*\.\(js\|css\)\)"/"\1?v=$(PKG_VERSION)"/g' \
			"$$$$src"; \
	done
endef

define Package/$(PKG_NAME)/install
	if [ -d $(PKG_BUILD_DIR)/luasrc ]; then \
	  $(INSTALL_DIR) $(1)$(LUCI_LIBRARYDIR); \
	  cp -pR $(PKG_BUILD_DIR)/luasrc/* $(1)$(LUCI_LIBRARYDIR)/; \
	  $(FIND) $(1)$(LUCI_LIBRARYDIR)/ -type f -name '*.luadoc' | $(XARGS) rm; \
	  $(if $(CONFIG_LUCI_SRCDIET),$(call SrcDiet,$(1)$(LUCI_LIBRARYDIR)/),true); \
	  $(call SubstituteVersion,$(1)$(LUCI_LIBRARYDIR)/); \
	else true; fi
	if [ -d $(PKG_BUILD_DIR)/htdocs ]; then \
	  $(INSTALL_DIR) $(1)$(HTDOCS); \
	  cp -pR $(PKG_BUILD_DIR)/htdocs/* $(1)$(HTDOCS)/; \
	  $(if $(CONFIG_LUCI_JSMIN),$(call JsMin,$(1)$(HTDOCS)/),true); \
	  $(if $(CONFIG_LUCI_CSSTIDY),$(call CssTidy,$(1)$(HTDOCS)/),true); \
	else true; fi
	if [ -d $(PKG_BUILD_DIR)/root ]; then \
	  $(INSTALL_DIR) $(1)/; \
	  cp -pR $(PKG_BUILD_DIR)/root/* $(1)/; \
	else true; fi
	if [ -d $(PKG_BUILD_DIR)/src ]; then \
	  $(call Build/Install/Default) \
	  $(CP) $(PKG_INSTALL_DIR)/* $(1)/; \
	else true; fi
endef

ifneq ($(LUCI_DEFAULTS),)
define Package/$(PKG_NAME)/postinst
[ -n "$${IPKG_INSTROOT}" ] || {$(foreach script,$(LUCI_DEFAULTS),
	(. /etc/uci-defaults/$(script)) && rm -f /etc/uci-defaults/$(script))
	exit 0
}
endef
endif


FF_BUILD_PACKAGES:=$(PKG_NAME)

$(foreach pkg,$(FF_BUILD_PACKAGES),$(eval $(call BuildPackage,$(pkg))))
