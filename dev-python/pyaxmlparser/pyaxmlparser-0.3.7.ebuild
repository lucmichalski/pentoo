# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_{4,5,6} )
inherit distutils-r1

DESCRIPTION="Parser for Android XML file and get Application Name without using Androguard"
HOMEPAGE="https://github.com/appknox/pyaxmlparser"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
KEYWORDS="~amd64"
SLOT="0"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]"
