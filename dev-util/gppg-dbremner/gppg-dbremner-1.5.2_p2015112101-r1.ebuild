# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

KEYWORDS="~amd64 ~ppc ~x86"
RESTRICT="mirror"

SLOT="0"

USE_DOTNET="net45"
IUSE="+${USE_DOTNET} debug"

inherit xbuild

NAME="gppg"
HOMEPAGE="https://github.com/dbremner/${NAME}"
DESCRIPTION="C# version of lex (Garden Point Lex)"
LICENSE="BSD" # https://gppg.codeplex.com/license

SRC_URI="https://github.com/ArsenShnurkov/shnurise-tarballs/archive/${CATEGORY}/${PN}/${PN}-${PV}.tar.gz -> ${CATEGORY}-${PN}-${PV}.tar.gz"
S="${WORKDIR}/shnurise-tarballs-${CATEGORY}-${PN}-${PN}-${PV}"

src_prepare() {
	eapply "${FILESDIR}/output-path.patch"
	eapply_user
}

src_compile() {
	exbuild "GPPG.sln"
}

src_install() {
	insinto "/usr/share/${PN}"
	if use debug; then
		newins bin/Debug/Gppg.exe Gppg.exe
		make_wrapper gppg "/usr/bin/mono --debug /usr/share/${PN}/gppg.exe"
	else
		newins bin/Release/Gppg.exe gppg.exe
		make_wrapper gppg "/usr/bin/mono /usr/share/${PN}/gppg.exe"
	fi
}
