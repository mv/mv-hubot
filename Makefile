# vim:ft=make:ts=8:sts=8:sw=8:noet:tw=80:wrap:list

# VERSION :=$(shell bash version.sh )
# RELEASE :=$(shell ls -1 dist/*.noarch.rpm 2>/dev/null | wc -l )
TOKEN :=$(shell bash config/slack-token.sh)

.PHONY: create-stack  \
	update-stack  \
	delete-stack  \
	list-stacks \
	create-env  \
	config      \
	test        \
	install     \
	clean

all:
	@echo "Tasks:"
	@echo "    make create-stack    - Cloudformation create EB stack"
	@echo "    make update-stack    - Cloudformation update EB stack"
	@echo "    make list-solutions  - list current EB solutionstacks"
	@echo "    make create-env   - Cloudformation create EB env"
	@echo "    make config       - Run a simple configuration CLI program"
	@echo "    make test         - Run tests"
	@echo "    make install      - Install on local system"
	@echo "    make clean        - Get rid of scratch and byte files"

var:
	@echo "Token: $(TOKEN)"

eb-init:
	eb init hubot-eb \
	    -p Node.js   \
	    -k marcus_anirul_id_rsa \
	    --region $(AWS_DEFAULT_REGION)  \
	    --profile default

eb-create-sample:
	eb create                \
	    hubot-sample         \
	    --platform node.js   \
	    --region=us-west-2   \
	    --cname hubot-sample \
	    --envvars APP=hubot,OWNER=mv \
	    --tags    App=hubot,Owner=mv \
	    --instance_type=t2.micro     \
	    --sample

eb-create-single:
	eb create                \
	    hubot-single         \
	    --platform node.js   \
	    --region=us-west-2   \
	    --cname hubot-single \
	    --envvars APP=hubot,OWNER=mv,HUBOT_SLACK_TOKEN=$(TOKEN) \
	    --tags    App=hubot,Owner=mv \
	    --instance_type=t2.micro     \
	    --single

eb-create-green:
	eb create                \
	    hubot-green          \
	    --platform node.js   \
	    --region=us-west-2   \
	    --cname hubot-green  \
	    --envvars APP=hubot,OWNER=mv,HUBOT_SLACK_TOKEN=$(TOKEN) \
	    --tags    App=hubot,Owner=mv \
	    --instance_type=t2.micro     \
	    --elb-type classic           \
	    --vpc.id vpc-b45ed0d1        \

eb-create-blue:
	eb create                \
	    hubot-blue           \
	    --platform node.js   \
	    --region=us-west-2   \
	    --cname hubot-blue   \
	    --envvars APP=hubot,OWNER=mv,HUBOT_SLACK_TOKEN=$(TOKEN) \
	    --tags    App=hubot,Owner=mv \
	    --instance_type=t2.micro     \
	    --elb-type classic           \
	    --vpc.id vpc-b45ed0d1        \
	    --vpc.ec2subnets subnet-5e17763b,subnet-ceac2bb9,subnet-ea9c46b3

create-stack:
	aws cloudformation create-stack \
	    --stack-name=hubot-eb       \
	    --template-body=file://./config/eb-app.cf.yaml \
	    --output=text

update-stack:
	aws cloudformation update-stack \
	    --stack-name=hubot-eb       \
	    --template-body=file://./config/eb-app.cf.yaml \
	    --output=text

delete-stack:
	aws cloudformation delete-stack \
	    --stack-name=hubot-eb       \
	    --output=text


list-stacks:
	aws elasticbeanstalk list-available-solution-stacks \
	    --output=text | egrep ^SOLUTIONSTACKS | grep -i node | sort

config:
	./bin/diamond-setup --configfile=conf/diamond.conf

test:
	./test.py

install: version
	./setup.py install --root $(DESTDIR)

clean:
	rm -rf ./node_modules/*
	find . -name '*.pyc' -delete

version:
	./version.sh > version.txt

