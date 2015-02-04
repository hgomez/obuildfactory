usage:
	@echo make centos7-openjdk8
	@echo make centos7-openjdk9

clean:
	sudo rm -rf build


obuildfactory-%: %
	cat $< | sudo docker build -t obuildfactory-$< -

%-openjdk8: obuildfactory-%
	mkdir -p build/$@/sources
	mkdir -p build/$@/binaries
	sudo docker run \
		-v `pwd`/build/$@/binaries:/openjdk/OBF_DROP_DIR \
		-v `pwd`/build/$@/sources:/openjdk/sources \
		 $< ./obuildfactory/openjdk8/linux/standalone-job.sh 

%-openjdk9: obuildfactory-%
	mkdir -p build/$@/sources
	mkdir -p build/$@/binaries
	sudo docker run \
		-v `pwd`/build/$@/binaries:/openjdk/OBF_DROP_DIR \
		-v `pwd`/build/$@/sources:/openjdk/sources \
		 $< ./obuildfactory/openjdk9/linux/standalone-job.sh 

