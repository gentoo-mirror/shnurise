# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
RESTRICT="mirror"
KEYWORDS="~amd64"
SLOT="0"

USE_DOTNET="net46"
IUSE="+${USE_DOTNET} +gac developer debug doc"

inherit gac dotnet

GITHUB_ACCOUNT="mono"
GITHUB_PROJECTNAME="linux-packaging-msbuild"
EGIT_COMMIT="431c7ec5857a3ee5df758c09948719490025ef94"
SRC_URI="https://github.com/${GITHUB_ACCOUNT}/${GITHUB_PROJECTNAME}/archive/${EGIT_COMMIT}.tar.gz -> ${GITHUB_PROJECTNAME}-${GITHUB_ACCOUNT}-${PV}.tar.gz"
S="${WORKDIR}/${GITHUB_PROJECTNAME}-${EGIT_COMMIT}"

HOMEPAGE="https://docs.microsoft.com/visualstudio/msbuild/msbuild"
DESCRIPTION="Microsoft Build Engine (MSBuild) is an XML-based platform for building applications"
LICENSE="MIT" # https://github.com/mono/linux-packaging-msbuild/blob/master/LICENSE

COMMON_DEPEND=">=dev-lang/mono-5.2.0.196
	dev-dotnet/msbuild-tasks-api
	developer? ( dev-dotnet/msbuild-tasks-api[developer] )
	dev-dotnet/system-reflection-metadata
	developer? ( dev-dotnet/system-reflection-metadata[developer] )
	dev-dotnet/system-collections-immutable
	developer? ( dev-dotnet/system-collections-immutable[developer] )
"
RDEPEND="${COMMON_DEPEND}
"
DEPEND="${COMMON_DEPEND}
	dev-dotnet/buildtools
	>=dev-dotnet/msbuildtasks-1.5.0.240
"

PROJ0=Microsoft.Build.Tasks
PROJ0_DIR=src/Tasks
PROJ1=Microsoft.Build
PROJ1_DIR=src/Build
PROJ2=MSBuild
PROJ2_DIR=src/MSBuild

src_prepare() {
	eapply "${FILESDIR}/dir.props.diff"
	eapply "${FILESDIR}/dir.targets.diff"
	eapply "${FILESDIR}/src-dir.targets.diff"
	eapply "${FILESDIR}/tasks.patch"
	sed -i 's/CurrentAssemblyVersion = "15.1.0.0"/CurrentAssemblyVersion = "15.3.0.0"/g' "${S}/src/Shared/Constants.cs" || die
	sed -i 's/Microsoft.Build.Tasks.Core, Version=15.1.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a/Microsoft.Build.Tasks.Core, Version=15.3.0.0, Culture=neutral, PublicKeyToken=0738eb9f132ed756/g' "${S}/src/Tasks/Microsoft.Common.tasks" || die
	sed -i 's/PublicKeyToken=b03f5f7f11d50a3a/PublicKeyToken=0738eb9f132ed756/g' "${S}/src/Build/Resources/Constants.cs" || die
	cp "${FILESDIR}/mono-${PROJ1}.csproj" "${S}/${PROJ1_DIR}/" || die
	cp "${FILESDIR}/mono-${PROJ2}.csproj" "${S}/${PROJ2_DIR}/" || die
	eapply_user
}

src_compile() {
	if use developer; then
		SARGS=/p:DebugSymbols=True
	else
		SARGS=/p:DebugSymbols=False
	fi

	if use debug; then
		CONFIGURATION=Debug
		if use developer; then
			SARGS=${SARGS} /p:DebugType=full
		fi
	else
		CONFIGURATION=Release
		if use developer; then
			SARGS=${SARGS} /p:DebugType=pdbonly
		fi
	fi

	VER=1.0.27.0
	KEY="${FILESDIR}/mono.snk"

	exbuild_raw /v:detailed  /p:MonoBuild=true /p:TargetFrameworkVersion=v4.6 "/p:Configuration=${CONFIGURATION}" ${SARGS} "/p:VersionNumber=${VER}" "/p:RootPath=${S}" "/p:SignAssembly=true" "/p:AssemblyOriginatorKeyFile=${KEY}" "${S}/${PROJ0_DIR}/${PROJ0}.csproj"
	sn -R "${S}/bin/${CONFIGURATION}/x86/Unix/Output/${PROJ0}.Core.dll" "${KEY}" || die

	exbuild_raw /v:detailed /p:TargetFrameworkVersion=v4.6 "/p:Configuration=${CONFIGURATION}" ${SARGS} "/p:VersionNumber=${VER}" "/p:RootPath=${S}" "/p:SignAssembly=true" "/p:AssemblyOriginatorKeyFile=${KEY}" "${S}/${PROJ2_DIR}/mono-${PROJ2}.csproj"
	sn -R "${PROJ1_DIR}/bin/${CONFIGURATION}/${PROJ1}.dll" "${KEY}" || die
}

src_install() {
	if use debug; then
		CONFIGURATION=Debug
	else
		CONFIGURATION=Release
	fi

	egacinstall "${S}/bin/${CONFIGURATION}/x86/Unix/Output/${PROJ0}.Core.dll"
	einstall_pc_file "${PN}" "${PV}" "${PROJ0}"

	egacinstall "${PROJ1_DIR}/bin/${CONFIGURATION}/${PROJ1}.dll"
	einstall_pc_file "${PN}" "${PV}" "${PROJ1}"

	insinto "/usr/share/${PN}/Roslyn"
	doins "${FILESDIR}/Microsoft.CSharp.Core.targets"
	insinto "/usr/share/${PN}"
	newins "${PROJ2_DIR}/bin/${CONFIGURATION}/${PROJ2}.exe" MSBuild.exe
	doins "${S}/src/Tasks/Microsoft.Common.tasks"
	doins "${S}/src/Tasks/Microsoft.Common.targets"
	doins "${S}/src/Tasks/Microsoft.Common.overridetasks"
	doins "${S}/src/Tasks/Microsoft.CSharp.targets"
	doins "${S}/src/Tasks/Microsoft.CSharp.CurrentVersion.targets"
	doins "${S}/src/Tasks/Microsoft.Common.CurrentVersion.targets"
	doins "${S}/src/Tasks/Microsoft.NETFramework.props"
	doins "${S}/src/Tasks/Microsoft.NETFramework.CurrentVersion.props"
	doins "${S}/src/Tasks/Microsoft.NETFramework.targets"
	doins "${S}/src/Tasks/Microsoft.NETFramework.CurrentVersion.targets"

	if use debug; then
		make_wrapper msbuild "/usr/bin/mono --debug /usr/share/${PN}/MSBuild.exe"
	else
		make_wrapper msbuild "/usr/bin/mono /usr/share/${PN}/MSBuild.exe"
	fi
}