#!/bin/bash

#set -x

function clone_package() {
    pkg=$1
    if [ ! -d $pkg ]; then
	git clone https://github.com/groonga/$pkg
    else
	(cd $pkg; git pull --rebase)
    fi
}

function get_package_name() {
    name=$1
    case $name in
	g|groonga)
	    pkg=groonga
	    ;;
	n|normalizer)
	    pkg=groonga-normalizer-mysql
	    ;;
	m|mroonga)
	    pkg=mroonga
	    ;;
    esac
    echo $pkg
}

function get_latest_version() {
    name=$1
    pkg=`get_package_name $name`
    if [ ! -d $pkg ]; then
	clone_package $pkg
    fi
    VERSION=`git tag | tail -n 1 | sed -e 's/v//'`
    echo $VERSION
}

function download_archive() {
    mkdir -p $VERSION
    if [ ! -f $VERSION/groonga-$VERSION.tar.gz ]; then
	wget http://packages.groonga.org/source/groonga/groonga-$VERSION.tar.gz -O $VERSION/groonga-$VERSION.tar.gz
    fi
}

function build_package() {
    cd $SCRIPT_DIR/$VERSION
    pkg=$1
    case $pkg in
	clean)
	    rm -fr $pkg-$VERSION
	    tar xf $pkg-$VERSION.tar.gz
	    rsync -avz $SCRIPT_DIR/$pkg/packages/debian $pkg-$VERSION/
	    ;;
	*)
	    rsync -avz --delete $SCRIPT_DIR/$pkg/packages/debian/ $pkg-$VERSION/debian/
	    ;;
    esac
    if [ ! -f $pkg_$VERSION.orig.tar.gz ]; then
	cp $pkg-$VERSION.tar.gz $pkg_$VERSION.orig.tar.gz
    fi
    cd $pkg-$VERSION
    #debuild -us -uc -nc
    sed -i -e 's/Kouhei Sutou <kou@clear-code.com>/HAYASHI Kentaro <hayashi@clear-code.com>/' debian/changelog
    #debuild -us -uc -j2
}

function copy_packages() {
    POOL=$SCRIPT_DIR/repositories/armhf/debian/pool/unstable/main/g/groonga
    mv *.deb $POOL/
    mv *.orig.tar.gz $POOL/
    mv *.dsc $POOL/
    mv *.xz $POOL/
    mv *.changes $POOL/
}

FULL_PATH=`realpath $0`
SCRIPT_DIR=`dirname $FULL_PATH`
echo $SCRIPT_DIR

case $1 in
    g|groonga|n|normalizer|m|mroonga)
	VERSION=`get_latest_version`
	echo $VERSION
	download_archive $1
	build_package $1
	copy_packages $1
	;;
    *)
	usage
	;;
esac
