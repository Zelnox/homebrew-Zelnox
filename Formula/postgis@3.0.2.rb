class PostgisAT302 < Formula
  desc "Adds support for geographic objects to PostgreSQL"
  homepage "https://postgis.net/"
  url "https://download.osgeo.org/postgis/source/postgis-3.0.2.tar.gz"
  sha256 "a3a1641dfd73c83924088a185bdb8b35567b3d1dc8d0887f9e4b492e228ab2ca"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url "https://download.osgeo.org/postgis/source/"
    regex(/href=.*?postgis[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  head do
    url "https://git.osgeo.org/gitea/postgis/postgis.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "gpp" => :build
  depends_on "pkg-config" => :build
  depends_on "gdal" # for GeoJSON and raster handling
  depends_on "geos"
  depends_on "json-c" # for GeoJSON and raster handling
  depends_on "pcre"
  depends_on "zelnox/zelnox/postgresql@12.4"
  depends_on "proj"
  depends_on "protobuf-c" # for MVT (map vector tiles) support
  depends_on "sfcgal" # for advanced 2D/3D functions

  def install
    ENV.deparallelize

    args = [
      "--with-projdir=#{Formula["proj"].opt_prefix}",
      "--with-jsondir=#{Formula["json-c"].opt_prefix}",
      "--with-pgconfig=#{Formula["postgresql@12.4"].opt_bin}/pg_config",
      "--with-protobufdir=#{Formula["protobuf-c"].opt_bin}",
      # Unfortunately, NLS support causes all kinds of headaches because
      # PostGIS gets all of its compiler flags from the PGXS makefiles. This
      # makes it nigh impossible to tell the buildsystem where our keg-only
      # gettext installations are.
      "--disable-nls",
    ]

    system "./autogen.sh" if build.head?
    system "./configure", *args
    system "make"

    mkdir "stage"
    system "make", "install", "DESTDIR=#{buildpath}/stage"

    bin.install Dir["stage/**/bin/*"]
    lib.install Dir["stage/**/lib/*"]
    include.install Dir["stage/**/include/*"]
    # (doc/"postgresql/extension").install Dir["stage/**/share/doc/postgresql/extension/*"] # empty
    (share/"postgresql/extension").install Dir["stage/**/share/postgresql@12.4/extension/*"] # /postgresql?
    pkgshare.install Dir["stage/**/contrib/postgis-*/*"]
    (share/"postgis_topology").install Dir["stage/**/contrib/postgis_topology-*/*"]

    # pg_formula_share = Formula["postgresql@12.4"].opt_share/"postgresql@12.4/extension/"
    # (Formula["postgresql@12.4"].opt_share/"postgresql@12.4/extension").install Dir["stage/**/share/postgresql@12.4/extension/postgi*.control"]
    # (Formula["postgresql@12.4"].opt_share/"postgresql@12.4/extension").install Dir["stage/**/share/postgresql@12.4/extension/postgi*.sql"]
    # system "cp", "stage/usr/local/opt/postgresql@12.4/share/postgresql@12.4/extension/postgis.control", pg_formula_share.to_s
    # FileUtils.cp Dir[(share/"postgresql/extension/postgis*.control")], pg_formula_share
    #
    # NOTE does a mv operation not permitted? Tried Formula#install, system cp, FileUtils. By hand works:
    #
    # The control file is used to manage in pg if an extension is enabled or not
    # cp /usr/local/opt/postgis@3.0.2/share/postgresql/extension/postgi*.control /usr/local/opt/postgresql@12.4/share/postgresql@12.4/extension/
    # cp /usr/local/opt/postgis@3.0.2/share/postgresql/extension/postgi*.sql /usr/local/opt/postgresql@12.4/share/postgresql@12.4/extension/
    # The lib files is used when are actually trying to access the extension functionality
    # cp /usr/local/opt/postgis@3.0.2/lib/postgresql/* /usr/local/opt/postgresql@12.4/lib/postgresql/

    # Extension scripts
    bin.install %w[
      utils/create_undef.pl
      utils/postgis_proc_upgrade.pl
      utils/postgis_restore.pl
      utils/profile_intersects.pl
      utils/test_estimation.pl
      utils/test_geography_estimation.pl
      utils/test_geography_joinestimation.pl
      utils/test_joinestimation.pl
    ]

    man1.install Dir["doc/**/*.1"]
  end

  test do
    require "base64"
    (testpath/"brew.shp").write ::Base64.decode64 <<~EOS
      AAAnCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAoOgDAAALAAAAAAAAAAAAAAAA
      AAAAAADwPwAAAAAAABBAAAAAAAAAFEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
      AAAAAAAAAAAAAAAAAAEAAAASCwAAAAAAAAAAAPA/AAAAAAAA8D8AAAAAAAAA
      AAAAAAAAAAAAAAAAAgAAABILAAAAAAAAAAAACEAAAAAAAADwPwAAAAAAAAAA
      AAAAAAAAAAAAAAADAAAAEgsAAAAAAAAAAAAQQAAAAAAAAAhAAAAAAAAAAAAA
      AAAAAAAAAAAAAAQAAAASCwAAAAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAAAAA
      AAAAAAAAAAAABQAAABILAAAAAAAAAAAAAAAAAAAAAAAUQAAAAAAAACJAAAAA
      AAAAAEA=
    EOS
    (testpath/"brew.dbf").write ::Base64.decode64 <<~EOS
      A3IJGgUAAABhAFsAAAAAAAAAAAAAAAAAAAAAAAAAAABGSVJTVF9GTEQAAEMA
      AAAAMgAAAAAAAAAAAAAAAAAAAFNFQ09ORF9GTEQAQwAAAAAoAAAAAAAAAAAA
      AAAAAAAADSBGaXJzdCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgICAgIFBvaW50ICAgICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgU2Vjb25kICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgICAgICBQb2ludCAgICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgIFRoaXJkICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgICAgICAgUG9pbnQgICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgICBGb3VydGggICAgICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgICAgICAgIFBvaW50ICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgICAgQXBwZW5kZWQgICAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgICAgICAgICBQb2ludCAgICAgICAgICAgICAgICAgICAgICAg
      ICAgICAgICAgICAg
    EOS
    (testpath/"brew.shx").write ::Base64.decode64 <<~EOS
      AAAnCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARugDAAALAAAAAAAAAAAAAAAA
      AAAAAADwPwAAAAAAABBAAAAAAAAAFEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
      AAAAAAAAAAAAAAAAADIAAAASAAAASAAAABIAAABeAAAAEgAAAHQAAAASAAAA
      igAAABI=
    EOS
    result = shell_output("#{bin}/shp2pgsql #{testpath}/brew.shp")
    assert_match(/Point/, result)
    assert_match(/AddGeometryColumn/, result)
  end
end
