# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

DESCRIPTION="AIC8800D80 USB Wi-Fi driver, Bluetooth firmware loader and ACL ZLP quirk"
HOMEPAGE="https://github.com/shenmintao/aic8800d80"

AIC_COMMIT="fab5be8bd6d25715e690d0df21d72689887ec2a7"
SRC_URI="https://github.com/shenmintao/aic8800d80/archive/${AIC_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${AIC_COMMIT}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

src_prepare() {
	default

	local quirk="${S}/drivers/aic8800/aic_zlp_quirk/aic_zlp_quirk.c"

	# The adapter enumerates as A69C:8D81. The Wi-Fi and firmware-loader
	# tables already match A69C:8D81 through USB_VENDOR_ID_AIC; only the
	# companion ZLP quirk still carries the upstream 368B:8D81 identifier.
	sed -i \
		-e 's/0x368b/0xa69c/g' \
		-e 's/368b:8d81/a69c:8d81/g' \
		-e 's/usb:v368Bp8D81/usb:va69cp8D81/g' \
		"${quirk}" ||
		die "Failed to update the AIC USB vendor ID in the Bluetooth ZLP quirk"

	grep -q 'AIC_USB_VENDOR_ID[[:space:]]+0xa69c' "${quirk}" ||
		die "AIC Bluetooth ZLP vendor ID correction missing"
	grep -q 'MODULE_ALIAS("usb:va69cp8D81' "${quirk}" ||
		die "AIC Bluetooth ZLP module alias correction missing"
}

src_compile() {
	grep -q '^CONFIG_KPROBES=y' "${KV_OUT_DIR}/.config" ||
		die "The target kernel must have CONFIG_KPROBES=y for aic_zlp_quirk"

	local -a modlist=(
		"aic_load_fw=kernel/drivers/net/wireless/aic8800:drivers/aic8800:drivers/aic8800/aic_load_fw:modules"
		"aic8800_fdrv=kernel/drivers/net/wireless/aic8800:drivers/aic8800:drivers/aic8800/aic8800_fdrv:modules"
		"aic_zlp_quirk=kernel/drivers/bluetooth/aic8800:drivers/aic8800/aic_zlp_quirk:drivers/aic8800/aic_zlp_quirk:modules"
	)

	local -a modargs=(
		"KDIR=${KV_OUT_DIR}"
		"KVER=${KV_FULL}"
		"CONFIG_PLATFORM_UBUNTU=y"
		"CONFIG_USE_FW_REQUEST=n"
	)

	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install

	insinto /lib/firmware/aic8800D80
	doins "${S}"/fw/aic8800D80/*
}
