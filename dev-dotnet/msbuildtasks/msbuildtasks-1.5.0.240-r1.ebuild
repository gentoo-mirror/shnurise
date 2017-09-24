# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
SLOT="0"

KEYWORDS="~amd64 ~ppc ~x86"
USE_DOTNET="net45"

inherit dotnet gac mono-pkg-config

HOMEPAGE="https://github.com/loresoft/msbuildtasks"
EGIT_COMMIT="014ed0f7a69f4936d7b3b438a5ceca78f902e0ef"
SRC_URI="${HOMEPAGE}/archive/${EGIT_COMMIT}.tar.gz -> ${PN}-${PV}.tar.gz
	https://github.com/mono/mono/raw/master/mcs/class/mono.snk"
RESTRICT="mirror"
NAME="msbuildtasks"
S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"

DESCRIPTION="The MSBuild Community Tasks Project is an open source project for MSBuild tasks."
LICENSE="BSD" # https://github.com/loresoft/msbuildtasks/blob/master/LICENSE

IUSE="+${USE_DOTNET} +debug developer doc"

COMMON_DEPEND=">=dev-lang/mono-4.0.2.5
	>=dev-dotnet/dotnetzip-semverd-1.9.3-r2
"
RDEPEND="${COMMON_DEPEND}
"
DEPEND="${COMMON_DEPEND}
"

KEY2="${DISTDIR}/mono.snk"

function output_filename ( ) {
    local DIR=""
    if use debug; then
	DIR="Debug"
    else
	DIR="Release"
    fi
    echo "Source/MSBuild.Community.Tasks/bin/${DIR}/MSBuild.Community.Tasks.dll"
}

function deploy_dir ( ) {
    echo "/usr/lib/mono/${EBUILD_FRAMEWORK}"
}

src_prepare() {
	eapply "${FILESDIR}/csproj.patch"
	eapply "${FILESDIR}/location.patch"
	eapply_user
}

src_compile() {
	exbuild_strong "Source/MSBuild.Community.Tasks/MSBuild.Community.Tasks.csproj"
	sn -R "$(output_filename)" "${KEY2}" || die
}

src_install() {
	insinto "$(deploy_dir)"
	doins "$(output_filename)"
	doins "Source/MSBuild.Community.Tasks/MSBuild.Community.Tasks.Targets"

	einstall_pc_file "${PN}" "${PV}" "MSBuild.Community.Tasks"
}

pkg_postinst()
{
	egacadd "$(deploy_dir)/MSBuild.Community.Tasks.dll"
}

pkg_prerm()
{
	egacdel "MSBuild.Community.Tasks"
}
