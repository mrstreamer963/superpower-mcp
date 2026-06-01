build:
	docker build -t superpower-mcp:latest .

start:
	docker run -it --name superpower-mcp superpower-mcp:latest
