name = "libunistring"
description =
  "This library provides functions for manipulating Unicode strings and for manipulating C strings according to the Unicode standard."
homepage = "https://www.gnu.org/software/libunistring/"
license = "https://www.gnu.org/software/libunistring/manual/html_node/Licenses.html"
manteiners = "Diogo-ss"
url = "https://ftp.gnu.org/gnu/libunistring/libunistring-${{ version }}.tar.gz"

checkver = {
  url = "https://www.gnu.org/software/libunistring/#TOCdownloading",
  regex = "libunistring%-(.-)%.tar",
}

function install()
  system {
    "./configure",
    "--disable-dependency-tracking",
    "--disable-silent-rules",
    "--prefix=" .. pkgdir,
  }

  system { "make" }

  system { "make", "install" }
end
