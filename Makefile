
sign-packages:
	./sign-packages.sh 45499429 repositories/armhf/ 'wheezy jessie unstable'

update-repository:
	./update-repository.sh groonga repositories/armhf/ 'armhf' 'wheezy jessie unstable'
	./update-repository.sh groonga-normalizer-mysql repositories/armhf/ 'armhf' 'wheezy jessie unstable'
	./update-repository.sh mroonga repositories/armhf/ 'armhf' 'wheezy jessie unstable'

sign-repository:
	./sign-repository.sh 45499429 repositories/armhf/ 'wheezy jessie unstable'

upload:
	rsync -avz --progress --delete repositories/armhf/debian/ packages@packages.groonga.org:public/armhf/debian/

try-upload:
	rsync -n -avz --progress --delete repositories/armhf/debian/ packages@packages.groonga.org:public/armhf/debian/

download:
	rsync -avz --progress --delete packages@packages.groonga.org:public/armhf/debian/ repositories/armhf/debian/
