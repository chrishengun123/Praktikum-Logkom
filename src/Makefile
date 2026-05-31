BUILD_DIR := build
TARGET    := $(BUILD_DIR)/logkomtubes.exe
SRC       := $(shell find . -name "*.pl" -not -path "./$(BUILD_DIR)/*")

CONSULT_FLAGS := $(foreach f, $(SRC), --consult-file $(f))

.PHONY: runi build run clean

runi:
	gprolog $(CONSULT_FLAGS)

run:
	gprolog $(CONSULT_FLAGS) --query-goal "main"

build:
	@mkdir -p $(BUILD_DIR)
	@rm -f $(TARGET)
	gplc $(SRC) -o $(TARGET)

clean:
	rm -rf $(BUILD_DIR)