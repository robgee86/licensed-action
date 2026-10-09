# Changelog

## [0.5.0](https://github.com/robgee86/licensed-action/compare/v0.4.0...v0.5.0) (2026-10-09)


### Features

* add the react-native ecosystem ([#11](https://github.com/robgee86/licensed-action/issues/11)) ([c9beada](https://github.com/robgee86/licensed-action/commit/c9beada3cab1e9a0fcb51a56764892154d08506e))

## [0.4.0](https://github.com/robgee86/licensed-action/compare/v0.3.0...v0.4.0) (2026-10-08)


### ⚠ BREAKING CHANGES

* mount at /src, share one cache volume and drop the -action image suffix ([#10](https://github.com/robgee86/licensed-action/issues/10))

### Features

* keep the installed dependencies in the cache instead of the working tree ([#8](https://github.com/robgee86/licensed-action/issues/8)) ([7d06c3f](https://github.com/robgee86/licensed-action/commit/7d06c3f3b9c352da3e2fbdfd207425ff89b960e1))
* mount at /src, share one cache volume and drop the -action image suffix ([#10](https://github.com/robgee86/licensed-action/issues/10)) ([83dc62b](https://github.com/robgee86/licensed-action/commit/83dc62b47e5de2d52e094f19fb96dfb2c6712d8a))

## [0.3.0](https://github.com/robgee86/licensed-action/compare/v0.2.0...v0.3.0) (2026-10-08)


### ⚠ BREAKING CHANGES

* ship the Gradle image per JDK, as gradle-jdk17 and gradle-jdk21, replacing gradle ([#6](https://github.com/robgee86/licensed-action/issues/6))
* name record files without the colon of Gradle coordinates ([#5](https://github.com/robgee86/licensed-action/issues/5))

### Features

* ship the Gradle image per JDK, as gradle-jdk17 and gradle-jdk21, replacing gradle ([#6](https://github.com/robgee86/licensed-action/issues/6)) ([e9cc9b6](https://github.com/robgee86/licensed-action/commit/e9cc9b6ca609b375c5d1edc8b120a9e78e4ec96c))


### Bug Fixes

* name record files without the colon of Gradle coordinates ([#5](https://github.com/robgee86/licensed-action/issues/5)) ([01e7589](https://github.com/robgee86/licensed-action/commit/01e75893a368f1e2b54a66ef436d943ddd17e54e))

## [0.2.0](https://github.com/robgee86/licensed-action/compare/v0.1.0...v0.2.0) (2026-10-08)


### Features

* keep committed NOTICE files current and deduplicated, and check them in CI ([1ae0d93](https://github.com/robgee86/licensed-action/commit/1ae0d93306533d4b3465ea82732a0c6698ceec0d))


### Bug Fixes

* bump licensed-notice-deduplicate to v1.1.0 and document the image commands ([#3](https://github.com/robgee86/licensed-action/issues/3)) ([fc131b5](https://github.com/robgee86/licensed-action/commit/fc131b5e10d040702d1e09fb636570a06c7c8270))

## 0.1.0 (2026-10-07)


### Features

* add licensed composite action with multi-ecosystem base image and release-please ([3d45492](https://github.com/robgee86/licensed-action/commit/3d4549205701ae00043503f33c9f8fadaa2ad93f))
* publish an image per ecosystem built with bake and test them on fixtures ([f17ce68](https://github.com/robgee86/licensed-action/commit/f17ce682072fa578e4b81d9544fdbbc7fe20c20b))
