# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
KEYWORDS="amd64 ~x86"
RESTRICT="mirror"

SLOT="0"

USE_DOTNET="net45"
IUSE="+${USE_DOTNET}"

inherit msbuild mono-pkg-config gac

NAME="nhibernate-contrib-old"
# https://sourceforge.net/projects/nhcontrib/
HOMEPAGE="https://github.com/pruiz/nhibernate-contrib-old"

EGIT_COMMIT="eada73cce086a6457e5e64b0413b97a8f53863ac"
SRC_URI="https://github.com/pruiz/${NAME}/archive/${EGIT_COMMIT}.tar.gz -> ${CATEGORY}-${PN}-${PV}.tar.gz
	https://github.com/mono/mono/raw/main/mcs/class/mono.snk"
S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"

DESCRIPTION="Contributions to NHibernate"
LICENSE="LGPL-2.0" # https://sourceforge.net/directory/license:lgpl/

CDEPEND="|| ( >=dev-lang/mono-5.4.0.167 <dev-lang/mono-9999 )
	dev-dotnet/nhibernate-core:3
	"
RDEPEND="${CDEPEND}
"
DEPEND="${CDEPEND}
"

PATH_TO_PROJ="src/NHibernate.Linq/src/NHibernate.Linq"
METAFILE_TO_BUILD=NHibernate.Linq
ASSEMBLY_NAME="NHibernate.Linq"

KEY2="${DISTDIR}/mono.snk"
ASSEMBLY_VERSION="${PV}"

function output_filename ( ) {
	local DIR=""
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi
	echo "${PATH_TO_PROJ}/bin/${DIR}/${ASSEMBLY_NAME}.dll"
}

src_prepare() {
	#cp "${FILESDIR}/${METAFILE_TO_BUILD}-${PV}.csproj" "${S}/${PATH_TO_PROJ}/${METAFILE_TO_BUILD}.csproj" || die
	#cp "${FILESDIR}/CommonAssemblyInfo-${PV}.cs" "${S}/${PATH_TO_PROJ}/../CommonAssemblyInfo.cs" || die
	cat <<-METADATA >"${S}/src/NHibernate.Linq/src/NHibernate.Linq/AssemblyInfo.cs" || die
	    [assembly: System.Reflection.AssemblyVersion("1.0.0.0")]
	METADATA
	eapply_user
}

TOOLS_VERSION=4.0

src_compile() {
	emsbuild /p:TargetFrameworkVersion=v4.6 "/p:SignAssembly=true" "/p:PublicSign=true" "/p:AssemblyOriginatorKeyFile=${KEY2}" /p:VersionNumber="${ASSEMBLY_VERSION}" "${S}/${PATH_TO_PROJ}/${METAFILE_TO_BUILD}.csproj"
	sn -R "$(output_filename)" "${KEY2}" || die
}

src_install() {
	elib "$(output_filename)"

	insinto "/gac"
	doins "$(output_filename)"
}

pkg_preinst()
{
	echo mv "${D}/gac/${ASSEMBLY_NAME}.dll" "${T}/${ASSEMBLY_NAME}.dll"
	mv "${D}/gac/${ASSEMBLY_NAME}.dll" "${T}/${ASSEMBLY_NAME}.dll" || die
	echo rm -rf "${D}/gac"
	rm -rf "${D}/gac" || die
}

pkg_postinst()
{
	egacadd "${T}/${ASSEMBLY_NAME}.dll"
	rm "${T}/${ASSEMBLY_NAME}.dll" || die
}

pkg_prerm()
{
	egacdel "${ASSEMBLY_NAME}, Version=${ASSEMBLY_VERSION}, Culture=neutral, PublicKeyToken=0738eb9f132ed756"
}
