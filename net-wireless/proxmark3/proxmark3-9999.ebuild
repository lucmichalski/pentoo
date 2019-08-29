# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit udev

if [ "${PV}" = "9999" ]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/RfidResearchGroup/proxmark3.git"
else
	HASH_COMMIT="1ac5211601b50b82b41737dce0c3a72d9e0374ac"
	SRC_URI="https://github.com/RfidResearchGroup/${PN}/archive/${HASH_COMMIT}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
	S=${WORKDIR}/${PN}-${HASH_COMMIT}
fi
DESCRIPTION="A general purpose RFID tool for Proxmark3 hardware"
HOMEPAGE="https://github.com/RfidResearchGroup/proxmark3"

LICENSE="GPL-2"
SLOT="0"
IUSE="deprecated +firmware +pm3rdv4"

RDEPEND="virtual/libusb:0
	sys-libs/ncurses:*[tinfo]
	dev-qt/qtcore:5
	dev-qt/qtwidgets:5
	dev-qt/qtgui:5
	sys-libs/readline:=
	dev-util/astyle"
DEPEND="${RDEPEND}
	firmware? ( sys-devel/gcc-arm-none-eabi )"


src_compile(){
	#first we set platform
	if use pm3rdv4; then
		echo 'PLATFORM=PM3RDV4' > Makefile.platform
		echo 'PLATFORM_EXTRAS=BTADDON' >> Makefile.platform
	else
		echo 'PLATFORM=PM3OTHER' > Makefile.platform
	fi
	export PM3_SHARE_PATH=/usr/share/${PN}
	export V=1
	if use firmware; then
		emake all
	elif use deprecated; then
		emake client/proxmark3 mfkey nonce2key
	else
		emake client/proxmark3
	fi
}

src_install(){
	dobin client/proxmark3
	if use deprecated; then
		#install some tools
		exeinto /usr/share/proxmark3/tools
		doexe tools/mfkey/mfkey{32,64}
		doexe tools/nonce2key/nonce2key
	fi
	#install main lua and scripts
	insinto /usr/share/proxmark3/lualibs
	doins client/lualibs/*
	insinto /usr/share/proxmark3/luascripts
	doins client/luascripts/*
	if use firmware; then
		exeinto /usr/share/proxmark3/firmware
		doexe client/flasher
		insinto /usr/share/proxmark3/firmware
		doins armsrc/obj/fullimage.elf
		doins bootrom/obj/bootrom.elf
		insinto /usr/share/proxmark3/jtag
		doins recovery/*.bin
	fi
	udev_dorules driver/77-pm3-usb-device-blacklist.rules
}

pkg_postinst() {
	if use firmware; then
		einfo "flasher is located in /usr/share/proxmark3/firmware/"
		if use pm3rdv4; then
			ewarn "Please note, all firmware and recovery files are intended for the Proxmark3 RDV4"
			ewarn "including support for the optional blueshark accessory."
			ewarn "If this is not what you intended please unset the pm3rdv4 use flag for generic firmware"
		else
			ewarn "Please note, all firmware and recovery files are built for a generic target."
			ewarn "If you have a Proxmark3 RDV4 you should set the pm3rdv4 use flag for an improved firmware"
		fi
	fi
}