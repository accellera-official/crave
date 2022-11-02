#!/bin/sh

package=z3
package_capital=Z3
version=4.6.0
cmake_files_dir=$base_dir/$package_capital-git

if [ -z "$build" ] ; then 
  echo '$build is undefined'
  exit 1
fi
if [ -z "$package_dir" ] ; then 
  echo '$build is undefined'
  exit 1
fi

source=nosourcefile
build_dir=$build/$package_capital-$version

download() {
  cd $cache &&
  curl -L -O https://github.com/Z3Prover/$package/archive/refs/tags/$package-$version.tar.gz
}

unpack() {
  rm -fR $build_dir &&
  cd $cache &&
  tar zxf $package-$version.tar.gz &&
  cp -R $cache/$package-$package-$version $build_dir
}
  
pre_build() 
{
  patch -d $build_dir -p0 < $base_dir/$package_capital-$version/$package-$package-$version\__permutation_matrix.patch
}
 
build_install() {
  num_threads=4;
  echo $num_threads
  if [ -z "$target" ] ; then
    echo '$target is undefined'
    exit 1
  fi
  cd "$build_dir" &&
  ./configure --staticlib --prefix="$target" &&
  cd build &&
  make -j $num_threads &&
  make install &&
  install_cmake_files $cmake_files_dir &&
  cp Z3Config.cmake "$target"
}
