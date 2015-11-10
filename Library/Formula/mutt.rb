# Note: Mutt has a large number of non-upstream patches available for
# it, some of which conflict with each other. These patches are also
# not kept up-to-date when new versions of mutt (occasionally) come
# out.
#
# To reduce Homebrew's maintenance burden, new patches are not being
# accepted for this formula. We would be very happy to see members of
# the mutt community maintain a more comprehesive tap with better
# support for patches.

class MuttPatched < Formula
  desc "Mongrel of mail user agents (part elm, pine, mush, mh, etc.)"
  homepage "http://www.mutt.org/"
  url "https://bitbucket.org/mutt/mutt/downloads/mutt-1.5.24.tar.gz"
  mirror "ftp://ftp.mutt.org/pub/mutt/mutt-1.5.24.tar.gz"
  sha256 "a292ca765ed7b19db4ac495938a3ef808a16193b7d623d65562bb8feb2b42200"

  bottle do
    revision 1
    sha256 "a5e74878cf5660dc32b93a7580f1e449a163dec163e1c5eaf2b8db1f2582e7ba" => :el_capitan
    sha256 "bc2e5da8f4488a9e6e9f89d716abf0fd2050d80c64b6748fb9f3b751d13e4473" => :yosemite
    sha256 "22da691ae8ed70425a9b2f3027652320b6484a8ec65a9efbc7710286d3d9c666" => :mavericks
  end

  head do
    url "http://dev.mutt.org/hg/mutt#default", :using => :hg

    resource "html" do
      url "http://dev.mutt.org/doc/manual.html", :using => :nounzip
    end
  end

  unless Tab.for_name("signing-party").with? "rename-pgpring"
    conflicts_with "signing-party",
      :because => "mutt installs a private copy of pgpring"
  end

  conflicts_with "tin",
    :because => "both install mmdf.5 and mbox.5 man pages"

  option "with-debug", "Build with debug option enabled"
  option "with-sidebar-patch", "Build with sidebar patch"
  option "with-trash-patch", "Apply trash folder patch"
  option "with-s-lang", "Build against slang instead of ncurses"
  option "with-ignore-thread-patch", "Apply ignore-thread patch"
  option "with-pgp-verbose-mime-patch", "Apply PGP verbose mime patch"
  option "with-pgp-multiple-crypt-hook-patch", "Apply PGP multiple-crypt-hook patch"
  option "with-pgp-combined-crypt-hook-patch", "Apply PGP combined-crypt-hook patch"
  option "with-confirm-attachment-patch", "Apply confirm attachment patch"

  depends_on "openssl"
  depends_on "tokyo-cabinet"
  depends_on "s-lang" => :optional
  depends_on "gpgme" => :optional
  depends_on "autoconf" => :build
  depends_on "automake" => :build

  patch do
    url "http://localhost.lu/mutt/patches/trash-folder"
    sha1 "6c8ce66021d89a063e67975a3730215c20cf2859"
  end if build.with? "trash-patch"

  # original source for this went missing, patch sourced from Arch at
  # https://aur.archlinux.org/packages/mutt-ignore-thread/
  if build.with? "ignore-thread-patch"
    patch do
      url "https://gist.githubusercontent.com/mistydemeo/5522742/raw/1439cc157ab673dc8061784829eea267cd736624/ignore-thread-1.5.21.patch"
      sha256 "7290e2a5ac12cbf89d615efa38c1ada3b454cb642ecaf520c26e47e7a1c926be"
    end
  end

  patch do
    url "http://localhost.lu/mutt/patches/patch-1.5.23.sc.multiple-crypt-hook.1"
    sha1 "697aae4e643f1e8f50c27b894ee6bfaab38d3119"
  end if build.with? "pgp-multiple-crypt-hook-patch"

  patch do
    url "http://localhost.lu/mutt/patches/patch-1.5.23.sc.crypt-combined.1"
    sha1 "2a12fe0a071e8cf7fe6f29336c6dadbccf95cdea"
  end if build.with? "pgp-combined-crypt-hook-patch"

  patch do
    url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
    sha1 "94da52d50508d8951aa78ca4b073023414866be1"
  end if build.with? "confirm-attachment-patch"

  if build.with? "confirm-attachment-patch"
    patch do
      url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
      sha256 "da2c9e54a5426019b84837faef18cc51e174108f07dc7ec15968ca732880cb14"
    end
  end

  patch do
    url "https://raw.github.com/nedos/mutt-sidebar-patch/master/mutt-sidebar.patch"
    sha1 "1e151d4ff3ce83d635cf794acf0c781e1b748ff1"
  end if build.with? "sidebar-patch"

  def install
    user_admin = Etc.getgrnam("admin").mem.include?(ENV["USER"])

    args = %W[
      --disable-dependency-tracking
      --disable-warnings
      --prefix=#{prefix}
      --with-ssl=#{Formula["openssl"].opt_prefix}
      --with-sasl
      --with-gss
      --enable-imap
      --enable-smtp
      --enable-pop
      --enable-hcache
      --with-tokyocabinet
    ]

    # This is just a trick to keep 'make install' from trying
    # to chgrp the mutt_dotlock file (which we can't do if
    # we're running as an unprivileged user)
    args << "--with-homespool=.mbox" unless user_admin

    args << "--with-slang" if build.with? "s-lang"
    args << "--enable-gpgme" if build.with? "gpgme"

    if build.with? "debug"
      args << "--enable-debug"
    else
      args << "--disable-debug"
    end

    system "./prepare", *args
    system "make"

    # This permits the `mutt_dotlock` file to be installed under a group
    # that isn't `mail`.
    # https://github.com/Homebrew/homebrew/issues/45400
    if user_admin
      inreplace "Makefile", /^DOTLOCK_GROUP =.*$/, "DOTLOCK_GROUP = admin"
    end

    system "make", "install"
    doc.install resource("html") if build.head?
  end

  test do
    system bin/"mutt", "-D"
  end
end
