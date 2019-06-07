# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGO_PN="github.com/kotakanbe/goval-dictionary"
EGO_VENDOR=(
	"github.com/asaskevich/govalidator         v9"
	"github.com/dgrijalva/jwt-go               v3.2.0"
	"github.com/go-redis/redis                 v6.14.2"
	"github.com/go-sql-driver/mysql            v1.4.1"
	"github.com/go-stack/stack                 v1.8.0"
	"github.com/google/subcommands             46f0354f63152e8801bb460d26f5b6c4c878efbb"
	"github.com/htcat/htcat                    v1.0.2"
	"github.com/inconshreveable/log15          v2.14"
	"github.com/jinzhu/gorm                    v1.9.1"
	"github.com/jinzhu/inflection              04140366298a54a039076d798123ffa108fff46c"
	"github.com/k0kubun/pp                     v2.3.0"
	"github.com/labstack/echo                  v2.2.0"
	"github.com/labstack/gommon                v0.2.8"
	"github.com/lib/pq                         v1.0.0"
	"github.com/mattn/go-colorable             v0.0.9"
	"github.com/mattn/go-isatty                v0.0.4"
	"github.com/valyala/bytebufferpool         v1.0.0"
	"github.com/valyala/fasttemplate           dcecefd839c4193db0d35b88ec65b4c12d360ab0"
	"github.com/ymomoi/goval-parser            0a0be1dd9d0855b50be0be5a10ad3085382b6d59"
	"gopkg.in/yaml.v2                          v2.2.1 github.com/go-yaml/yaml"
)

inherit golang-vcs-snapshot user

DESCRIPTION="Build a local copy of OVAL. Server mode for easy querying"
HOMEPAGE="https://vuls.io/ https://github.com/kotakanbe/goval-dictionary"

SRC_URI="https://github.com/kotakanbe/goval-dictionary/archive/v${PV}.tar.gz -> ${P}.tar.gz
	${EGO_VENDOR_URI}"

KEYWORDS="~amd64"
LICENSE="Apache-2.0"
IUSE="policykit"
SLOT=0

RDEPEND="policykit? ( sys-auth/polkit )"
DEPEND="
	dev-go/go-sqlite3:=
	dev-go/go-sys:=
	>=dev-lang/go-1.12"

pkg_setup() {
	if use policykit; then
		enewgroup vuls
		enewuser vuls -1 -1 "/var/lib/vuls" vuls
	fi
}

src_prepare() {
	cp "${FILESDIR}"/goval-dictionary.initd "${T}" || die

	if ! use policykit; then
		sed -e "s/^USER=\"vuls\"/USER=\"root\"/" \
			-e "s/^GROUP=\"vuls\"/GROUP=\"root\"/" \
			-i "${T}"/goval-dictionary.initd || die
	fi

	default
}

src_compile() {
	GOPATH="${WORKDIR}/${P}:$(get_golibdir_gopath)" \
		GOCACHE="${T}/go-cache" \
		go build -v -work -x -ldflags="-X main.version=${PV} -s -w" ./... "${EGO_PN}" || die
}

src_install() {
	GOPATH="${WORKDIR}/${P}:$(get_golibdir_gopath)" \
		GOCACHE="${T}/go-cache" \
		go install -v -work -x -ldflags="-X main.version=${PV} -s -w" ./... "${EGO_PN}" || die

	rm -rf "${S}/src/${EGO_PN}/vendor" || die
	golang_install_pkgs

	exeinto "$(get_golibdir_gopath)"/bin
	doexe bin/${PN}

	newinitd "${T}"/goval-dictionary.initd goval-dictionary
	newconfd "${FILESDIR}"/goval-dictionary.confd goval-dictionary

	if use policykit; then
		insinto "/usr/share/polkit-1/rules.d"
		doins "${FILESDIR}"/polkit/10-${PN}.rules

		insinto "/usr/share/polkit-1/actions"
		doins "${FILESDIR}"/polkit/io.vuls.pkexec.${PN}.policy

		dodir "/usr/bin"
		cat > "${D}/usr/bin/${PN}" <<-_EOF_ || die
			#!/bin/sh
			pkexec --user vuls "$(get_golibdir_gopath)/bin/${PN}" "\$@"
		_EOF_

		fperms 0755 "/usr/bin/${PN}"
	else
		dosym "$(get_golibdir_gopath)/bin/${PN}" "/usr/bin/${PN}"
	fi

	keepdir "/var/log/vuls" "/var/lib/vuls"

	dodoc src/"${EGO_PN}"/{README.md,Dockerfile}
}

pkg_postinst() {
	if use policykit; then
		# enewuser is not support "--no-create-home"
		chown -R vuls:vuls \
			"${EROOT%/}/var/lib/vuls" \
			"${EROOT%/}/var/log/vuls" || die

		chmod 0750 \
			"${EROOT%/}/var/lib/vuls" \
			"${EROOT%/}/var/log/vuls" || die
	fi
}
