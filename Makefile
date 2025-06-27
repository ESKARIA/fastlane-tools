DEVICE_UDID ?= 
MATCH_LANE ?= match_generate_dev

.PHONY: default
default:
	@if [ -z "$(DEVICE_UDID)" ]; then \
		echo "❌ Укажите UDID устройства: make DEVICE_UDID=xxx"; \
		exit 1; \
	fi; \
	echo "📱 Добавляем устройство с UDID=$(DEVICE_UDID)"; \
	fastlane run register_device udid:$(DEVICE_UDID) name:NewDevice; \
	echo "♻️ Перегенерация provisioning профилей..."; \
	fastlane $(MATCH_LANE)
