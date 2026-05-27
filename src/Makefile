CONSULT_LIST := $(shell find . -name "*.pl" | awk '{print "--consult-file " $$1}')

BUILD_DIR := build
TARGET := $(BUILD_DIR)/logkomtubes
SRC := $(shell find . -name "*.pl")

.PHONY: runi build run

runi:
	gprolog $(CONSULT_LIST)
	
build:
	@mkdir -p $(BUILD_DIR)
	@rm -f $(TARGET)
	@gplc $(SRC) -o $(TARGET)

run: build
	./$(TARGET)
