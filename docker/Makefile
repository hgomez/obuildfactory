usage:
	@echo make centos7-openjdk8
	@echo make centos7-openjdk9

clean:
	sudo rm -rf build


obuildfactory-%: %
	cat $< | sudo docker build -t obuildfactory-$< --build-arg BUILD_UID=`id -u` -

%-openjdk8: obuildfactory-%
	mkdir -p build/$@/sources
	mkdir -p build/$@/binaries
	sudo docker run \
		-u `id -u` \
		-v `pwd`/build/$@/binaries:/openjdk/OBF_DROP_DIR \
		-v `pwd`/build/$@/sources:/openjdk/sources \
		 $< ./obuildfactory/openjdk8/linux/standalone-job.sh 

%-openjdk9: obuildfactory-% build/%-openjdk8/binaries/openjdk8
	mkdir -p build/$@/sources
	mkdir -p build/$@/binaries
	tar -C build/$@ -xjf build/$(shell echo $@ | sed 's/jdk9/jdk8/')/binaries/openjdk8/j2sdk-image-*.tar.bz2
	sudo docker run \
		-u `id -u` \
		-v `pwd`/build/$@/j2sdk-image:/openjdk/j2sdk-image \
		-v `pwd`/build/$@/binaries:/openjdk/OBF_DROP_DIR \
		-v `pwd`/build/$@/sources:/openjdk/sources \
		-e JAVA_HOME=/openjdk/j2sdk-image \
		 $< ./obuildfactory/openjdk9/linux/standalone-job.sh 

