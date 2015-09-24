class Gtkx3 < Formula
  desc "Toolkit for creating graphical user interfaces"
  homepage "http://gtk.org/"
  url "https://download.gnome.org/sources/gtk+/3.18/gtk+-3.18.0.tar.xz"
  sha256 "7fb8ae257403317d3852bad28d064d35f67e978b1fed8b71d5997e87204271b9"

  option :universal
  option "with-quartz-relocation", "Build with quartz relocation support"

  depends_on "pkg-config" => :build
  depends_on "jessevdk/gnome/gdk-pixbuf"
  depends_on "jasper" => :optional
  depends_on "jessevdk/gnome/atk"
  depends_on "jessevdk/gnome/gobject-introspection"
  depends_on "libepoxy"
  depends_on "jessevdk/gnome/gsettings-desktop-schemas" => :recommended
  depends_on "jessevdk/gnome/pango"
  depends_on "glib"
  depends_on "hicolor-icon-theme"

  patch :DATA

  def install
    ENV.universal_binary if build.universal?

    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --prefix=#{prefix}
      --disable-glibtest
      --enable-introspection=yes
      --disable-schemas-compile
      --enable-quartz-backend
      --disable-x11-backend
    ]

    args << "--enable-quartz-relocation" if build.with?("quartz-relocation")

    system "./configure", *args
    # necessary to avoid gtk-update-icon-cache not being found during make install
    bin.mkpath
    ENV.prepend_path "PATH", "#{bin}"

    system "make", "install"
    # Prevent a conflict between this and Gtk+2
    mv bin/"gtk-update-icon-cache", bin/"gtk3-update-icon-cache"
  end

  def post_install
    system "#{Formula["glib"].opt_bin}/glib-compile-schemas", "#{HOMEBREW_PREFIX}/share/glib-2.0/schemas"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <gtk/gtk.h>

      int main(int argc, char *argv[]) {
        gtk_disable_setlocale();
        return 0;
      }
    EOS
    atk = Formula["atk"]
    cairo = Formula["cairo"]
    fontconfig = Formula["fontconfig"]
    freetype = Formula["freetype"]
    gdk_pixbuf = Formula["gdk-pixbuf"]
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    libepoxy = Formula["libepoxy"]
    libpng = Formula["libpng"]
    pango = Formula["pango"]
    pixman = Formula["pixman"]
    flags = (ENV.cflags || "").split + (ENV.cppflags || "").split + (ENV.ldflags || "").split
    flags += %W[
      -I#{atk.opt_include}/atk-1.0
      -I#{cairo.opt_include}/cairo
      -I#{fontconfig.opt_include}
      -I#{freetype.opt_include}/freetype2
      -I#{gdk_pixbuf.opt_include}/gdk-pixbuf-2.0
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/gio-unix-2.0/
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{include}
      -I#{include}/gtk-3.0
      -I#{libepoxy.opt_include}
      -I#{libpng.opt_include}/libpng16
      -I#{pango.opt_include}/pango-1.0
      -I#{pixman.opt_include}/pixman-1
      -D_REENTRANT
      -L#{atk.opt_lib}
      -L#{cairo.opt_lib}
      -L#{gdk_pixbuf.opt_lib}
      -L#{gettext.opt_lib}
      -L#{glib.opt_lib}
      -L#{lib}
      -L#{pango.opt_lib}
      -latk-1.0
      -lcairo
      -lcairo-gobject
      -lgdk-3
      -lgdk_pixbuf-2.0
      -lgio-2.0
      -lglib-2.0
      -lgobject-2.0
      -lgtk-3
      -lintl
      -lpango-1.0
      -lpangocairo-1.0
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
__END__
--- a/testsuite/gtk/notify.c  2015-09-24 12:10:30.000000000 +0200
+++ b/testsuite/gtk/notify.c  2015-09-24 12:10:33.000000000 +0200
@@ -418,10 +418,10 @@
 #ifdef GDK_WINDOWING_X11
   if (GDK_IS_X11_DISPLAY (gdk_display_get_default ())) ;
   else
-#endif
   if (g_type_is_a (type, GTK_TYPE_PLUG) ||
       g_type_is_a (type, GTK_TYPE_SOCKET))
     return;
+#endif
 
 #ifdef GDK_WINDOWING_WAYLAND
   if (GDK_IS_WAYLAND_DISPLAY (gdk_display_get_default ()))
