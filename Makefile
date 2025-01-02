all: build

build:
	etc/grpc_tools.sh -I ./protos --ruby_out=./lib/anycable/protos --grpc_out=./lib/anycable/grpc ./protos/rpc.proto
	sed -i '' '/'rpc_pb'/d' ./lib/anycable/grpc/rpc_services_pb.rb
	sed -i '' 's/module RPC/module GRPC/g' ./lib/anycable/grpc/rpc_services_pb.rb
	bundle exec rubocop -A ./lib/anycable/protos ./lib/anycable/grpc

release:
	gem release anycable-core
	gem release anycable -t
	git push
	git push --tags
