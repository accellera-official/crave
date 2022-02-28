#!/bin/sh

version=4.6.0
branch=z3-4.6.0

cmake_files_dir=$base_dir/Z3-git

if [ -z "$build" ] ; then 
  echo '$build is undefined'
  exit 1
fi
if [ -z "$package_dir" ] ; then 
  echo '$build is undefined'
  exit 1
fi

package=Z3
source=nosourcefile
build_dir=$build/$package-$version
url='https://github.com/Z3Prover/z3.git'

download() {
  mkdir -p $cache/$package-$version &&
  cd $cache/$package-$version &&
  if [ -d .git ]; then
    git pull
  else
    git clone -b $branch $url --single-branch --depth=1 .
  fi
}

unpack() {
  cp -R $cache/$package-$version $build_dir
}
  
pre_build() 
{
  patch -d/"$build_dir" -p0 < $base_dir/Z3-4.6.0/z3-z3-4.6.0__permutation_matrix.patch
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
