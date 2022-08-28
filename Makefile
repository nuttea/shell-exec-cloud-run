all:
	@echo "clean  - Clean the nodejs project"
	@echo "build  - Build the nodejs project"
	@echo "deploy - Deploy the nodejs project"
	@echo "call - Call the nodejs project"

clean:
	cd nodejs; make clean

build:
	cd nodejs; make build

deploy:
	cd nodejs; make deploy

call:
	cd nodejs; make call