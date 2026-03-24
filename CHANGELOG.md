# Changelog

## 2.3.0.9

- [LDEV-6189](https://luceeserver.atlassian.net/browse/LDEV-6189) — fix malformed `Require-Bundle` symbolic name in MANIFEST.MF, was using Maven coordinates instead of OSGi `Bundle-SymbolicName`, causing flaky OSGi resolution failures on Lucee 7.0 cold start

## 2.3.0.8

- [LDEV-6100](https://luceeserver.atlassian.net/browse/LDEV-6100) — Jakarta compatibility, use reflection for `createPageContext`
- Add README
- Initial Maven build

## 2.3.0.7

- Switch to Maven build
- Add Sonatype deployment

## 1.0.0.0 (2017-10-25)

- Initial commit
