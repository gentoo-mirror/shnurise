# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit eutils linux-info mono-env flag-o-matic pax-utils versionator multilib-minimal

DESCRIPTION="Mono runtime and class libraries, a C# compiler/interpreter"
HOMEPAGE="http://www.mono-project.com/Main_Page"
SRC_URI="http://download.mono-project.com/sources/${PN}/nightly/${P}.tar.bz2"

LICENSE="MIT LGPL-2.1 GPL-2 BSD-4 NPL-1.1 Ms-PL GPL-2-with-linking-exception IDPL"
SLOT="0"

KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux"

IUSE="nls minimal pax_kernel xen doc"

COMMONDEPEND="
	!minimal? ( >=dev-dotnet/libgdiplus-2.10 )
	ia64? ( sys-libs/libunwind )
	nls? ( sys-devel/gettext )
"
RDEPEND="${COMMONDEPEND}
	|| ( www-client/links www-client/lynx )
"
DEPEND="${COMMONDEPEND}
	sys-devel/bc
	virtual/yacc
	pax_kernel? ( sys-apps/elfix )
	!dev-lang/mono-basic
"

S="${WORKDIR}/${PN}-$(get_version_component_range 1-3)"

pkg_pretend() {
	# https://github.com/gentoo/gentoo/blob/f200e625bda8de696a28338318c9005b69e34710/eclass/linux-info.eclass#L686
	# If CONFIG_SYSVIPC is not set in your kernel .config, mono will hang while compiling.
	# See http://bugs.gentoo.org/261869 for more info."
	CONFIG_CHECK="SYSVIPC"
	use kernel_linux && check_extra_config
}

multilib_src_install_all() {
	insinto "/"
	doins "${S}/mcs/class/mono.snk"
}

pkg_preinst() {
	einfo D="${D}"
	MONO_EXECUTABLE="${WORKDIR}/mono-4.9.0-abi_x86_32.x86/mono/mini/mono-sgen"
	if [ ! -f "${MONO_EXECUTABLE}" ]; then
		die "${MONO_EXECUTABLE}, MONO_EXECUTABLE is missing"
	fi
	SN_ASSEMBLY="${WORKDIR}/mono-4.9.0-abi_x86_32.x86/mcs/tools/security/sn.exe"
	if [ ! -f "${SN_ASSEMBLY}" ]; then
		die "${SN_ASSEMBLY}, SN_ASSEMBLY is missing"
	fi
	SNK_FILE="${D}/mono.snk"
	if [ ! -f "${SNK_FILE}" ]; then
		die "${SNK_FILE}, SNK_FILE is missing"
	fi
	"${MONO_EXECUTABLE}" "${SN_ASSEMBLY}" -i "${SNK_FILE}" "mono" || die
	rm "${SNK_FILE}" || die
}

pkg_setup() {
	linux-info_pkg_setup
	mono-env_pkg_setup
}

src_prepare() {
	# we need to sed in the paxctl-ng -mr in the runtime/mono-wrapper.in so it don't
	# get killed in the build proces when MPROTECT is enable. #286280
	# RANDMMAP kill the build proces to #347365
	# use paxmark.sh to get PT/XT logic #532244
	if use pax_kernel ; then
		ewarn "We are disabling MPROTECT on the mono binary."

		# issue 9 : https://github.com/Heather/gentoo-dotnet/issues/9
		sed '/exec "/ i\paxmark.sh -mr "$r/@mono_runtime@"' -i "${S}"/runtime/mono-wrapper.in || die "Failed to sed mono-wrapper.in"
	fi

	# mono build system can fail otherwise
	strip-flags

	eapply "${FILESDIR}/autofac.patch"

	default
	#eapply_user
	multilib_copy_sources
}

multilib_src_configure() {
	local myeconfargs=(
		--disable-silent-rules
		$(use_with xen xen_opt)
		--without-ikvm-native
		--disable-dtrace
		$(use_with doc mcs-docs)
		$(use_enable nls)
	)

	econf "${myeconfargs[@]}"
}

multilib_src_test() {
	cd mcs/tests || die
	emake check
}

multilib_src_install() {
	default_src_install

	# Remove files not respecting LDFLAGS and that we are not supposed to provide, see Fedora
	# mono.spec and http://www.mail-archive.com/mono-devel-list@lists.ximian.com/msg24870.html
	# for reference.
	rm -f "${ED}"/usr/lib/mono/{2.0,4.5}/mscorlib.dll.so || die
	rm -f "${ED}"/usr/lib/mono/{2.0,4.5}/mcs.exe.so || die
}
