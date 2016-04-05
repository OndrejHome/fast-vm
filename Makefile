bindir=/usr/bin
sbindir=/usr/sbin
datadir=/usr/share
libexecdir=/usr/libexec
sysconfdir=/etc

install:
	mkdir -p ${DESTDIR}/${bindir}
	install -pm 755 fast-vm ${DESTDIR}/${bindir}/fast-vm
	install -pm 755 fast-vm-net-cleanup ${DESTDIR}/${bindir}/fast-vm-net-cleanup
	mkdir -p ${DESTDIR}/${sbindir}
	install -pm 755 configure-fast-vm ${DESTDIR}/${sbindir}
	mkdir -p ${DESTDIR}/${libexecdir}
	install -pm 750 fast-vm-helper.sh ${DESTDIR}/${libexecdir}
	mkdir -p ${DESTDIR}/${datadir}/fast-vm
	install -pm 644 fast-vm-network.xml ${DESTDIR}/${datadir}/fast-vm
	install -pm 644 fast-vm.conf.defaults ${DESTDIR}/${datadir}/fast-vm/
	mkdir -p ${DESTDIR}/${sysconfdir}/sudoers.d/
	install -pm 640 fast-vm-sudoers ${DESTDIR}/${sysconfdir}/sudoers.d/
	mkdir -p ${DESTDIR}/${datadir}/bash-completion/completions
	install -pm 644 fast-vm.bash_completion ${DESTDIR}/${datadir}/bash-completion/completions/fast-vm
	mkdir -p ${DESTDIR}/${datadir}/man/man8
	install -pm 644 man/fast-vm.8 ${DESTDIR}/${datadir}/man/man8/
	install -pm 644 man/configure-fast-vm.8 ${DESTDIR}/${datadir}/man/man8/
	mkdir -p ${DESTDIR}/${datadir}/man/man5
	install -pm 644 man/fast-vm.conf.5 ${DESTDIR}/${datadir}/man/man5/
