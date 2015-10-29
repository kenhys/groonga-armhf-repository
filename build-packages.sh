#!/bin/bash

set -x

function clone_package() {
    cd $SCRIPT_DIR
    pkg=$1
    if [ ! -d $pkg ]; then
	if [ $pkg = "mroonga" ]; then
	    git clone https://github.com/mroonga/$pkg
	    cd mroonga
	    ./autogen.sh
	    ./configure --with-mysql-source=$HOME/work/mysql/mysql
	else
	    git clone https://github.com/groonga/$pkg
	fi
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
    cd $SCRIPT_DIR
    pkg=$1
    if [ ! -d $pkg ]; then
	clone_package $pkg
    fi
    cd $pkg
    VERSION=`git tag | tail -n 1 | sed -e 's/v//'`
    echo $VERSION
}

function download_archive() {
    cd $SCRIPT_DIR
    pkg=$1
    mkdir -p $VERSION
    if [ ! -f $VERSION/$pkg-$VERSION.tar.gz ]; then
	wget http://packages.groonga.org/source/$pkg/$pkg-$VERSION.tar.gz -O $VERSION/$pkg-$VERSION.tar.gz
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
	    if [ ! -d $pkg-$VERSION ]; then
		tar xf $pkg-$VERSION.tar.gz
	    fi
	    rsync -avz --delete $SCRIPT_DIR/$pkg/packages/debian/ $pkg-$VERSION/debian/
	    if [ $pkg = "mroonga" ]; then
		MYSQL_VERSION=`apt-cache show mysql-server | grep Version | awk '{print $2}'`
		sed -i -e "s/MYSQL_VERSION/${MYSQL_VERSION}/" $pkg-$VERSION/debian/control
	    fi
	    ;;
    esac
    if [ ! -f ${pkg}_$VERSION.orig.tar.gz ]; then
	cp $pkg-$VERSION.tar.gz ${pkg}_$VERSION.orig.tar.gz
    fi
    cd $pkg-$VERSION
    #debuild -us -uc -nc
    sed -i -e 's/Kouhei Sutou <kou@clear-code.com>/HAYASHI Kentaro <hayashi@clear-code.com>/' debian/changelog
    debuild -us -uc -j2
}

function copy_packages() {
    cd $SCRIPT_DIR/$VERSION
    pkg=$1
    case $pkg in
	groonga|groonga-normalizer-mysql)
	    POOL=$SCRIPT_DIR/repositories/armhf/debian/pool/unstable/main/g/$pkg
	    ;;
	mroonga)
	    POOL=$SCRIPT_DIR/repositories/armhf/debian/pool/unstable/main/m/$pkg
	    ;;
    esac
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
	PACKAGE=`get_package_name $1`
	VERSION=`get_latest_version $PACKAGE`
	echo $PACKAGE
	echo $VERSION
	download_archive $PACKAGE
	build_package $PACKAGE
	copy_packages $PACKAGE
	;;
    *)
	usage
	;;
esac
